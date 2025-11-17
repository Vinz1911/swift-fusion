//
//  FusionConnection.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final actor FusionConnection: Sendable {
    private let framer = FusionFramer()
    private var bytes = FusionBytes()
    private var endpoint: NWEndpoint
    private var connection: NetworkConnection<TCP>?
    
    /// The `FusionConnection` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
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
    public func start() async -> Void {
        connection = NetworkConnection(to: endpoint) { TCP() }
    }
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    public func cancel() async -> Void {
        guard let connection else { return }
        connection.tryNextEndpoint()
    }
    
    /// Send messages to a connected host
    ///
    /// - Parameter message: generic type send `String`, `Data` and `UInt16` based messages
    public func send<T: FusionMessage>(message: T) async throws -> Void {
        try await processing(with: message)
    }
    
    /// Receive a message from a connected host
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionBytes` generic message typ
    public func receive(_ completion: @Sendable @escaping (FusionMessage?, FusionBytes?) async throws -> Void) async throws -> Task<Void, Error> {
        try await processing { [weak self] message in
            guard let self else { return }
            try await completion(message, self.bytes)
        }
    }
}

// MARK: - Private API -

private extension FusionConnection {
    /// Process message data and send it to a host
    ///
    /// - Parameter data: message data
    private func processing<T: FusionMessage>(with message: T) async throws -> Void {
        guard let connection else { throw FusionConnectionError.deadConnection }
        let frame = try await framer.create(message: message)
        for chunk in frame.chunks {
            self.bytes.outbound = chunk.count
            try await connection.send(chunk)
        }
    }
    
    /// Process message data and parse it into a conform message
    ///
    /// - Parameter data: message data
    private func processing(_ completion: (@Sendable (FusionMessage) async throws -> Void)? = nil) async throws -> Task<Void, Error> {
        guard let connection else { throw FusionConnectionError.deadConnection }
        return Task(priority: .high) { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let data = try await connection.receive(atLeast: Int.minimum, atMost: Int.maximum).content
                // self.bytes.inbound = data.count
                let messages = try await self.framer.parse(data: data)
                for message in messages { if let completion { try await completion(message) } }
            }
        }
    }
}
