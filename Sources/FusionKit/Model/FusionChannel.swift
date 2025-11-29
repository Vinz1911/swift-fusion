//
//  FusionChannel.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public actor FusionChannel: FusionChannelProtocol, Sendable {    
    private let stream = AsyncThrowingStream.makeStream(of: FusionResult.self)
    private let framer = FusionFramer()
    private var weight: FusionWeight
    private var endpoint: NWEndpoint
    private var channel: NetworkConnection<TCP>?
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
    public init(host: String, port: UInt16, weight: FusionWeight = .medium) throws {
        if host.isEmpty || port == .zero { throw(FusionChannelError.invalidEndpoint) }
        self.endpoint = .hostPort(host: .init(host), port: .init(integerLiteral: port))
        self.weight = weight
    }
    
    /// Start a channel
    ///
    /// - Returns: non returning
    public func start(with priority: TaskPriority = .high) async {
        channel = NetworkConnection(to: endpoint) { TCP() }
        task = Task(priority: priority) { [weak self] in await self?.processing() }
        await handler()
    }
    
    /// Cancel the current channel
    ///
    /// - Returns: non returning
    public func cancel() async -> Void {
        if let task { task.cancel() }
        stream.continuation.finish()
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
    public nonisolated func receive() -> AsyncThrowingStream<FusionResult, Error> {
        return stream.stream
    }
}

// MARK: - Private API -

private extension FusionChannel {
    /// Channel handler for state updates
    ///
    /// Manages state updates for the active established channel
    private func handler() async -> Void {
        guard let channel else { return }
        channel.onStateUpdate { [weak self] _, state in guard let self else { return }
            Task(priority: .high) {
                if case .cancelled = state { stream.continuation.finish() }
                if case .waiting(let error) = state { stream.continuation.finish(throwing: error) }
                if case .failed(let error) = state { stream.continuation.finish(throwing: error) }
            }
        }
    }
    
    /// Process message data and send it to a host
    ///
    /// - Parameter message: generic type takes `FusionMessage`
    private func processing<T: FusionMessage>(with message: T) async throws -> Void {
        guard let channel else { return }
        let frame = try await framer.create(message: message)
        for chunk in frame.chunks(of: weight) {
            stream.continuation.yield(.report(.init(outbound: chunk.count)))
            try await channel.send(chunk)
        }
    }
    
    /// Process message data and parse it into a conform message
    ///
    /// - Parameter completion: async completion block contains `FusionMessage`
    private func processing() async -> Void {
        do {
            while !Task.isCancelled {
                guard let channel else { return }
                let data = try await channel.receive(atLeast: .minimum, atMost: weight.rawValue).content
                stream.continuation.yield(.report(.init(inbound: data.count)))
                let messages = try await self.framer.parse(data: data)
                for message in messages { stream.continuation.yield(.message(message)) }
            }
            stream.continuation.finish()
        } catch {
            stream.continuation.finish(throwing: error)
        }
    }
}
