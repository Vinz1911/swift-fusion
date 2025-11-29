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
    
    private var parameters: FusionParameters
    private var endpoint: NWEndpoint
    private var channel: NetworkConnection<TCP>?
    private var process: Task<Void, Error>?
    
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `FusionParameters`
    public init(host: String, port: UInt16, parameters: FusionParameters = .init()) throws {
        if host.isEmpty || port == .zero { throw(FusionChannelError.invalidEndpoint) }
        self.endpoint = .hostPort(host: .init(host), port: .init(integerLiteral: port))
        self.parameters = parameters
    }
    
    /// Start to establish a new channel
    ///
    /// Set config for `NetworkConnection` and establish new channel
    public func start() async throws {
        guard channel == nil else { channel = nil; throw FusionChannelError.alreadyEstablished}
        channel = NetworkConnection(to: endpoint, using: .parameters(initialParameters: .init(tls: parameters.tls, tcp: parameters.tcp)) { TCP() })
        process = Task(priority: parameters.priority) { [weak self] in await self?.processing() }
        try await established()
    }
    
    /// Cancel the current channel
    ///
    /// Stops the receiver and cancels the current channel
    public func cancel() async -> Void {
        if let process { process.cancel() }
        stream.continuation.finish(); channel = nil
    }
    
    /// Send messages over the established channel
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    public func send<T: FusionMessage>(message: T) async throws -> Void {
        try await processing(with: message)
    }
    
    /// Receive messages over the established channel
    ///
    /// - Returns: the iteratable `AsyncThrowingStream` contains `FusionResult`
    public nonisolated func receive() -> AsyncThrowingStream<FusionResult, Error> {
        return stream.stream
    }
}

// MARK: - Private API -

private extension FusionChannel {
    /// Validate channel establishment
    ///
    /// Checks if the channel was successful established
    private func established() async throws -> Void {
        let clock = ContinuousClock(), deadline = clock.now + .timeout
        while !Task.isCancelled {
            switch channel?.state { case .ready: return case .failed(let error), .waiting(let error): channel = nil; throw error default: break }
            guard clock.now < deadline else { channel = nil; throw FusionChannelError.channelTimeout }
            try await clock.sleep(for: .interval)
        }
    }
    
    /// Create message frame with `FusionFramer` and send it over the channel
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    private func processing<T: FusionMessage>(with message: T) async throws -> Void {
        guard let channel else { return }
        let frame = try await framer.create(message: message)
        for chunk in frame.chunks(of: parameters.leverage) {
            stream.continuation.yield(.report(.init(outbound: chunk.count)))
            try await channel.send(chunk)
        }
    }
    
    /// Receive message frames over the channel and parse it with `FusionFramer`
    ///
    /// Exposes the parsed `FusionMessage` and the `FusionReport`
    private func processing() async -> Void {
        do {
            while !Task.isCancelled {
                guard let channel else { return }
                let (data, _) = try await channel.receive(atLeast: .minimum, atMost: parameters.leverage.rawValue)
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
