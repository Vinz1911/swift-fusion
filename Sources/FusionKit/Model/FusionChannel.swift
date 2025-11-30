//
//  FusionChannel.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class FusionChannel: FusionChannelProtocol, @unchecked Sendable {
    private let (stream, continuation) = AsyncThrowingStream.makeStream(of: FusionResult.self)
    private var timer: DispatchSourceTimer?
    
    private let queue: DispatchQueue
    private let framer = FusionFramer()
    private let leverage: FusionLeverage
    private let channel: NWConnection
    
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - endpoint: the `NWEndpoint`
    ///   - parameters: the configurable `FusionParameters`
    public required init(using endpoint: NWEndpoint, parameters: FusionParameters = .init()) throws {
        self.channel = NWConnection(to: endpoint, using: .init(tls: parameters.tls, tcp: parameters.tcp))
        self.queue = DispatchQueue(label: UUID().uuidString, qos: parameters.qos)
        self.leverage = parameters.leverage
    }
    
    /// Start to establish a new channel
    ///
    /// Establish a new `FusionChannel` to a compatible booststrap
    public func start() -> Void {
        queue.async { [weak self] in guard let self else { return }
            state(); process(); channel.start(queue: queue)
        }
        queue.asyncAfter(deadline: .now() + .timeout) { [weak self] in
            guard self?.channel.state != .ready else { return }
            self?.channel.cancel(); self?.framer.reset()
            self?.continuation.finish(throwing: FusionChannelError.channelTimeout)
        }
    }
    
    /// Cancel an active channel
    ///
    /// The current active `FusionChannel` will be terminated
    public func cancel() -> Void {
        queue.async { [weak self] in self?.channel.cancel(); self?.framer.reset() }
    }
    
    /// Send a `FusionMessage` to a connected bootstraped
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    public func send<T: FusionMessage>(message: T) -> Void {
        queue.async { [weak self] in self?.process(with: message) }
    }
    
    /// Receive a message from a connected bootstraped
    ///
    /// - Parameter completion: contains `FusionResult` generic message typ
    public func receive(_ completion: @Sendable @escaping (Result<FusionResult, Error>) -> Void) -> Void {
        Task(priority: .userInitiated) {
            do {
                for try await message in stream { completion(.success(message)) }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Private API -

private extension FusionChannel {
    /// Channel handler for state updates
    ///
    /// Manages state updates for the active established channel
    private func state() -> Void {
        channel.stateUpdateHandler = { [weak self] state in
            if case .ready = state { self?.continuation.yield(.ready) }
            if case .cancelled = state { self?.continuation.finish() }
            if case .failed(let error) = state { self?.continuation.finish(throwing: error); self?.channel.cancel(); self?.framer.reset() }
        }
    }
    
    /// Dispatch tcp data from a message frame
    ///
    /// - Parameter content: the content `FusionMessage` to transmit
    private func process<T: FusionMessage>(with message: T) -> Void {
        channel.batch {
            do {
                let frame = try framer.create(message: message)
                for chunk in frame.chunks(of: leverage) {
                    channel.send(content: chunk, completion: .contentProcessed { [weak self] error in
                        self?.continuation.yield(.report(.init(outbound: chunk.count)))
                        if let error, error != NWError.posix(.ECANCELED) { self?.continuation.finish(throwing: error) }
                    })
                }
            } catch {
                continuation.finish(throwing: error); channel.cancel(); framer.reset()
            }
        }
    }
    
    /// Receive discontiguous `TCP` data frames
    ///
    /// The parsed `FusionMessage` from the current established `FusionChannel`
    private func process() -> Void {
        channel.batch {
            channel.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: leverage.rawValue) { [weak self] content, _, isComplete, error in
                if let error { if error != NWError.posix(.ECANCELED) { self?.continuation.finish(throwing: error); self?.channel.cancel(); self?.framer.reset() }; return }
                if let content {
                    do {
                        self?.continuation.yield(.report(.init(inbound: content.count)))
                        guard let messages = try self?.framer.parse(data: content) else { return }
                        for message in messages { self?.continuation.yield(.message(message)) }
                    } catch {
                        self?.continuation.finish(throwing: error); self?.channel.cancel(); self?.framer.reset()
                    }
                }
                if isComplete { self?.channel.cancel(); self?.framer.reset() } else { self?.process() }
            }
        }
    }
}
