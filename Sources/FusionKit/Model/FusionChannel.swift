//
//  FusionChannel.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public actor FusionChannel: /*FusionConnectionProtocol,*/ Sendable {
    private let stream = AsyncThrowingStream.makeStream(of: FusionResult.self)
    private let framer = FusionFramer()
    private var endpoint: NWEndpoint
    private var connection: NetworkConnection<TCP>?
    private var task: Task<Void, Error>?
    
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    public init(host: String, port: UInt16, parameters: NWParameters = .tcp) throws {
        if host.isEmpty { throw(FusionConnectionError.missingHost) }
        if port == .zero { throw(FusionConnectionError.missingPort) }
        self.endpoint = .hostPort(host: .init(host), port: .init(integerLiteral: port))
    }
    
    /// Start a connection
    ///
    /// - Returns: non returning
    public func start() async throws {
        connection = NetworkConnection(to: endpoint) { TCP() }
        task = Task { [weak self] in await self?.processing() }
    }
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    public func cancel() async -> Void {
        guard let connection else { return }
        stream.continuation.finish()
        if let task { task.cancel() }
        connection.tryNextEndpoint()
    }
    
    /// Send messages to a connected host
    ///
    /// - Parameter message: generic type takes `String`, `Data` and `UInt16` based messages
    public func send<T: FusionMessage>(message: T) async throws -> Void {
        try await processing(with: message)
    }
    
    /// Receive a message from a connected host
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionReport` generic message typ
    public func receive() async -> AsyncThrowingStream<FusionResult, Error> {
        return stream.stream
    }
}

// MARK: - Private API -

private extension FusionChannel {
    /// Process message data and send it to a host
    ///
    /// - Parameter message: generic type takes `FusionMessage`
    private func processing<T: FusionMessage>(with message: T) async throws -> Void {
        guard let connection else { throw FusionConnectionError.deadConnection }
        let frame = try await framer.create(message: message)
        for chunk in frame.chunks {
            stream.continuation.yield(.report(.init(outbound: chunk.count)))
            try await connection.send(chunk)
        }
    }
    
    /// Process message data and parse it into a conform message
    ///
    /// - Parameter completion: async completion block contains `FusionMessage`
    private func processing() async -> Void {
        guard let connection else { stream.continuation.finish(throwing: FusionConnectionError.deadConnection); return }
        defer { stream.continuation.finish() }
        do {
            while !Task.isCancelled {
                let data = try await connection.receive(atLeast: Int.minimum, atMost: Int.maximum).content
                stream.continuation.yield(.report(.init(inbound: data.count)))
                let messages = try await self.framer.parse(data: data)
                for message in messages { stream.continuation.yield(.message(message)) }
            }
        } catch {
            stream.continuation.finish(throwing: error)
        }
    }
}
