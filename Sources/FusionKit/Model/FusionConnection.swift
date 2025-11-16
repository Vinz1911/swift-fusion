//
//  FusionConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class FusionConnection: FusionConnectionProtocol, @unchecked Sendable {
    public var stateUpdateHandler: (@Sendable (FusionState) -> Void) = { _ in }
    
    private var result: (@Sendable (FusionResult) -> Void) = { _ in }
    private let queue: DispatchQueue
    private let framer = FusionFramer()
    private let connection: NWConnection
    
    /// The `FusionConnection` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, qos: DispatchQoS = .userInteractive) throws {
        if host.isEmpty { throw(FusionConnectionError.missingHost) }; if port == .zero { throw(FusionConnectionError.missingPort) }
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = DispatchQueue(label: UUID().uuidString, qos: qos)
    }
    
    /// Start a connection
    ///
    /// - Returns: non returning
    public func start() -> Void {
        queue.async { [weak self] in guard let self else { return }
            handler(); discontiguous(); connection.start(queue: queue)
        }
    }
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    public func cancel() -> Void {
        self.queue.async { [weak self] in guard let self else { return }
            cleanup()
        }
    }
    
    /// Send messages to a connected host
    ///
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    public func send<T: FusionMessage>(message: T) -> Void {
        self.queue.async { [weak self] in guard let self else { return }
            processing(with: message)
        }
    }
    
    /// Receive a message from a connected host
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionBytes` generic message typ
    public func receive(_ completion: @Sendable @escaping (FusionMessage?, FusionBytes?) -> Void) -> Void {
        result = { if case .message(let message) = $0 { completion(message, nil) }; if case .bytes(let bytes) = $0 { completion(nil, bytes) } }
    }
}

// MARK: - Private API -

private extension FusionConnection {
    /// Process message data and send it to a host
    ///
    /// - Parameter data: message data
    private func processing<T: FusionMessage>(with message: T) -> Void {
        do {
            let data = try framer.create(message: message)
            let queued = data.chunks; if !queued.isEmpty { for data in queued { transmission(data)} }
        } catch {
            stateUpdateHandler(.failed(error)); cleanup()
        }
    }
    
    /// Process message data and parse it into a conform message
    ///
    /// - Parameter data: message data
    private func processing(from data: DispatchData) -> Void {
        do {
            let messages = try framer.parse(data: data)
            for message in messages { self.result(.message(message)) }
        } catch {
            stateUpdateHandler(.failed(error)); cleanup()
        }
    }
    
    /// Clean and cancel connection
    ///
    /// - Returns: non returning
    private func cleanup() -> Void {
        connection.cancel(); framer.reset()
    }
    
    /// Connection state update handler handles different network connection states
    ///
    /// - Returns: non returning
    private func handler() -> Void {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .cancelled: stateUpdateHandler(.cancelled)
            case .failed(let error), .waiting(let error): cleanup(); stateUpdateHandler(.failed(error))
            case .ready: stateUpdateHandler(.ready)
            default: break }
        }
    }
    
    /// Transmit tcp data from a message frame
    ///
    /// - Parameter content: the content `Data` to transmit
    private func transmission(_ content: Data) -> Void {
        connection.batch {
            connection.send(content: content, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                result(.bytes(FusionBytes(outbound: content.count)))
                if let error, error != NWError.posix(.ECANCELED) { stateUpdateHandler(.failed(error)) }
            })
        }
    }
    
    /// Receives tcp data and parse it into a message frame
    ///
    /// - Returns: non returning
    private func discontiguous() -> Void {
        connection.batch {
            connection.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] content, _, isComplete, error in
                guard let self else { return }
                if let error { guard error != NWError.posix(.ECANCELED) else { return }; stateUpdateHandler(.failed(error)); cleanup(); return }
                if let content { result(.bytes(.init(inbound: content.count))); processing(from: content) }
                if isComplete { cleanup() } else { discontiguous() }
            }
        }
    }
}
