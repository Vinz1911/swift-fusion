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
    private var result: ResultBridge = { _ in }
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
    public required init(using endpoint: NWEndpoint, parameters: FusionParameters = .init()) {
        self.channel = NWConnection(to: endpoint, using: .init(tls: parameters.tls, tcp: parameters.tcp))
        self.queue = DispatchQueue(label: UUID().uuidString, qos: parameters.qos)
        self.leverage = parameters.leverage
    }
    
    /// Start to establish a new channel
    ///
    /// Establish a new `FusionChannel` to a compatible booststrap
    public func start() -> Void {
        channel.stateUpdateHandler = { [weak self] state in
            if case .ready = state { self?.result(.ready) }
            if case .failed(let error) = state { self?.result(.failed(error)) }
        }
        receiveMessage(); channel.start(queue: queue)
        channel.timeout(queue: queue) { [weak self] in self?.result(.failed(FusionChannelError.channelTimeout)) }
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
        queue.async { [weak self] in self?.sendMessage(with: message) }
    }
    
    /// Receive a message from a connected bootstraped
    ///
    /// - Parameter completion: contains `FusionResult` generic message typ
    public func receive(_ operation: @Sendable @escaping (FusionResult) -> Void) -> Void {
        result = { [weak self] result in if case .failed = result { self?.channel.cancel(); self?.framer.reset() }; operation(result) }
    }
}

// MARK: - Private API -

private extension FusionChannel {
    /// Send `Data` from a created generic `FusionMessage`
    ///
    /// - Parameter content: the generic `FusionMessage` to send
    private func sendMessage<T: FusionMessage>(with message: T) -> Void {
        channel.batch {
            let (frame, error) = framer.create(message: message); if let error { self.result(.failed(error)); return }
            for chunk in frame.chunks(of: leverage) {
                channel.send(content: chunk, completion: .contentProcessed { [weak self] error in
                    self?.result(.report(.init(outbound: chunk.count)))
                    if let error, error != NWError.posix(.ECANCELED) { self?.result(.failed(error)); }
                })
            }
        }
    }
    
    /// Receive `Data` and parse it into a generic `FusionMessage`
    ///
    /// The parsed `FusionMessage` from the current established `FusionChannel`
    private func receiveMessage() -> Void {
        channel.batch {
            channel.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: leverage.rawValue) { [weak self] content, _, isComplete, error in
                if let error { if error != NWError.posix(.ECANCELED) { self?.result(.failed(error)) }; return }
                if let content {
                    self?.result(.report(.init(inbound: content.count)))
                    guard let (messages, error) = self?.framer.parse(data: content) else { return }
                    if let error { self?.result(.failed(error)) }
                    for message in messages { self?.result(.message(message)) }
                }
                if isComplete { self?.channel.cancel(); self?.framer.reset() } else { self?.receiveMessage() }
            }
        }
    }
}
