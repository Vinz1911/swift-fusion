//
//  FusionTransport.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public actor FusionConnection: FusionConnectionProtocol, Sendable {
    private let framer = FusionFramer()
    private let (stream, continuation) = FusionStream.makeStream()
    private let parameters: FusionParameters
    
    private let endpoint: NWEndpoint
    private var connection: NetworkConnection<TCP>?
    private var process: Task<Void, Error>?
    
    /// The `FusionConnection` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the connected `NWEndpoint`
    ///   - parameters: network framework `FusionParameters`
    public init(using endpoint: NWEndpoint, parameters: FusionParameters = .init()) {
        self.endpoint = endpoint
        self.parameters = parameters
    }
    
    /// Start to establish a new connection
    ///
    /// Set config for `NetworkConnection` and establish new connection
    public func start() async throws -> Void {
        guard connection == nil else { connection = nil; throw FusionConnectionError.established }
        connection = NetworkConnection(to: endpoint, using: .parameters(initialParameters: parameters.parameters) { TCP() })
        process = Task(priority: parameters.priority) { [weak self] in
            do { try await self?.processing() } catch { self?.continuation.finish(throwing: error) }
        }
        if let connection { await framer.clear(); try await connection.timeout() }
    }
    
    /// Cancel the current connection
    ///
    /// Stops the receiver and cancels the current connection
    public func cancel() async -> Void {
        if let process { process.cancel() }
        connection = nil; continuation.finish()
    }
    
    /// Send messages over the established connection
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    public func send<Message: FusionMessage>(message: Message) async throws -> Void {
        try await processing(with: message)
    }
    
    /// Receive messages over the established connection
    ///
    /// - Returns: the iteratable `AsyncThrowingStream` contains `FusionResult`
    public nonisolated func receive() -> AsyncThrowingStream<FusionResult, Error> {
        return stream
    }
}

// MARK: - Private API Extension -

private extension FusionConnection {
    /// Create message frame with `FusionFramer` and send it over the connection
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    private func processing<Message: FusionMessage>(with message: Message) async throws -> Void {
        guard let connection, let message = message as? FusionFrame else { return }
        let frame = try framer.create(message: message)
        for chunk in frame.chunks(of: parameters.leverage) {
            try await connection.send(chunk); continuation.yield(.init(report: .init(outbound: chunk.count)))
        }
    }
    
    /// Receive message frames over the connection and parse it with `FusionFramer`
    ///
    /// Exposes the parsed `FusionMessage` and the `FusionReport`
    private func processing() async throws -> Void {
        while !Task.isCancelled { guard let connection else { return }
            let (data, _) = try await connection.receive(atMost: parameters.leverage.rawValue)
            continuation.yield(.init(report: .init(inbound: data.count)))
            let messages = try await self.framer.parse(slice: data, size: parameters.size)
            for message in messages { continuation.yield(.init(message: message)) }
        }
    }
}
