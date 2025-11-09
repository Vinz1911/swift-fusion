//
//  FKConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final actor FKConnection: FKConnectionProtocol, Sendable {
    public var bytes: FKBytes
    private var connection: NetworkConnection<TCP>? = nil
    private var endpoint: FKEndpoint
    private var framer: FKFramer
    private var task: Task<Void, Error>? = nil
    
    /// The `FKConnection` is a custom network framing protocol and implements the `Fusion Framing Protocol`.
    /// It's build on top of the `Network` framework standard library. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows a more fine grained control over the network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    public init(host: String, port: UInt16) throws {
        if host.isEmpty { throw(FKError.missingHost) }; if port == .zero { throw(FKError.missingPort) }
        endpoint = .init(host: .init(host), port: .init(integerLiteral: port))
        framer = .init(); bytes = .init()
    }
    
    /// Start a connection
    ///
    /// - Returns: non returning
    public func start() async throws -> Void {
        framer = .init()
        connection = NetworkConnection(to: .hostPort(host: endpoint.host, port: endpoint.port)) { TCP() }
    }
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    public func cancel() async throws -> Void {
        guard let connection else { return }
        connection.tryNextEndpoint()
        if let task { task.cancel() }
    }
    
    /// The current state
    ///
    /// - Returns: current `TCP.State`
    public func state() async -> NetworkChannel<TCP>.State? {
        guard let connection else { return nil }
        return connection.state
    }
    
    /// Send a message compliant to `FKMessage`
    ///
    /// - Parameter message: a `FKMessage` compliant message
    public func send<Message: FKMessage>(message: Message) async throws -> Void {
        guard let connection else { return }
        let message = try await framer.create(message: message)
        for chunk in message.chunks {
            bytes.outbound = chunk.count
            try await connection.send(chunk)
        }
    }
    
    /// Receive a message compliant to `FKMessage`
    ///
    /// - Parameter completion: async completion block
    public func receive(_ completion: (@Sendable (FKMessage) async throws -> Void)? = nil) async throws -> Void {
        guard let connection else { return }
        task = Task(priority: .high) {
            while !Task.isCancelled {
                let data = try await connection.receive(atMost: Int.maximum).content
                bytes.inbound = data.count
                for message in try await framer.parse(data: data) { try await completion?(message) }
            }
        }
        if let task { try await task.value }
    }
}
