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
    public var onStateUpdate: (@Sendable (FusionState) -> Void) = { _ in }
    
    private var result: (@Sendable (FusionResult) -> Void) = { _ in }
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let framer = FusionFramer()
    private let channel: NWConnection
    
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, qos: DispatchQoS = .userInteractive) throws {
        if host.isEmpty { throw(FusionChannelError.invalidHostName) }; if port == .zero { throw(FusionChannelError.invalidPortNumber) }
        self.channel = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = DispatchQueue(label: UUID().uuidString, qos: qos)
    }
    
    /// Start to establish a new channel
    ///
    /// Establish a new `FusionChannel` to a compatible booststrap
    public func start() -> Void {
        queue.async { [weak self] in guard let self else { return }
            handler(); discontiguous(); channel.start(queue: queue)
        }
        queue.asyncAfter(deadline: .now() + .timeout) { [weak self] in
            guard self?.channel.state != .ready else { return }
            self?.teardown(); self?.onStateUpdate(.failed(FusionChannelError.channelTimeout))
        }
    }
    
    /// Cancel an active channel
    ///
    /// The current active `FusionChannel` will be terminated
    public func cancel() -> Void {
        queue.async { [weak self] in
            self?.teardown()
        }
    }
    
    /// Send a `FusionMessage` to a connected bootstraped
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    public func send<T: FusionMessage>(message: T) -> Void {
        queue.async { [weak self] in
            self?.processing(with: message)
        }
    }
    
    /// Receive a message from a connected bootstraped
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionReport` generic message typ
    public func receive(_ completion: @Sendable @escaping (FusionMessage?, FusionReport?) -> Void) -> Void {
        result = { result in
            if case .message(let message) = result { completion(message, nil) }
            if case .bytes(let bytes) = result { completion(nil, bytes) }
        }
    }
}

// MARK: - Private API -

private extension FusionChannel {
    /// Clean and cancel `FusionChannel`
    ///
    /// The current active `FusionChannel` will be terminated cleaned
    private func teardown() -> Void {
        channel.cancel(); framer.reset()
    }
    
    /// Channel handler for state updates
    ///
    /// Manages state updates for the active established channel
    private func handler() -> Void {
        channel.stateUpdateHandler = { [weak self] state in
            if case .ready = state { self?.onStateUpdate(.ready) }
            if case .cancelled = state { self?.onStateUpdate(.cancelled) }
            if case .failed(let error) = state { self?.teardown(); self?.onStateUpdate(.failed(error)) }
        }
    }
    
    /// Process message data and send it to a connected bootstrap
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    private func processing<T: FusionMessage>(with message: T) -> Void {
        do {
            let frame = try framer.create(message: message)
            for chunk in frame.chunks { dispatch(chunk) }
        } catch {
            onStateUpdate(.failed(error)); teardown()
        }
    }
    
    /// Process message data, received rom a connected bootstrap
    ///
    /// - Parameter data: frame data as `DispatchData`
    private func processing(from data: DispatchData) -> Void {
        do {
            let messages = try framer.parse(data: data)
            for message in messages { result(.message(message)) }
        } catch {
            onStateUpdate(.failed(error)); teardown()
        }
    }
    
    /// Dispatch tcp data from a message frame
    ///
    /// - Parameter content: the content `Data` to transmit
    private func dispatch(_ content: Data) -> Void {
        channel.batch {
            channel.send(content: content, completion: .contentProcessed { [weak self] error in
                self?.result(.bytes(FusionReport(outbound: content.count)))
                if let error, error != NWError.posix(.ECANCELED) { self?.onStateUpdate(.failed(error)) }
            })
        }
    }
    
    /// Receive discontiguous `TCP` data frames
    ///
    /// The `DispatchData` received from a current established `FusionChannel`
    private func discontiguous() -> Void {
        channel.batch {
            channel.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] content, _, isComplete, error in
                if let error { if error != NWError.posix(.ECANCELED) { self?.onStateUpdate(.failed(error)); self?.teardown(); }; return }
                if let content { self?.result(.bytes(.init(inbound: content.count))); self?.processing(from: content) }
                if isComplete { self?.teardown() } else { self?.discontiguous() }
            }
        }
    }
}
