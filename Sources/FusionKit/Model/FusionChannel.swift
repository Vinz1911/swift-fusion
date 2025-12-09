//
//  FusionChannel.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public actor FusionChannel: FusionChannelProtocol {
    private var framer = FusionFramer()
    private let (stream, continuation) = FusionStream.makeStream()
    
    private var parameters: FusionParameters
    private var endpoint: NWEndpoint
    private var channel: NetworkConnection<TCP>?
    private var process: Task<Void, Error>?
    
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
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
    
    /// Start to establish a new channel
    ///
    /// Set config for `NetworkConnection` and establish new channel
    public func start() async throws -> Void {
        guard channel == nil else { channel = nil; throw FusionChannelError.alreadyEstablished }
        let parameter = NWParameters(tls: parameters.tls, tcp: parameters.tcp, serviceClass: parameters.serviceClass)
        channel = NetworkConnection(to: endpoint, using: .parameters(initialParameters: parameter) { TCP() })
        process = Task(priority: parameters.priority) { [weak self] in
            do { try await self?.processing() } catch { self?.continuation.finish(throwing: error) }
        }
        if let channel { await framer.clear(); try await channel.timeout() }
    }
    
    /// Cancel the current channel
    ///
    /// Stops the receiver and cancels the current channel
    public func cancel() async -> Void {
        if let process { process.cancel() }
        channel = nil; continuation.finish()
    }
    
    /// Send messages over the established channel
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    public func send<Message: FusionMessage>(message: Message) async throws -> Void {
        try await processing(with: message)
    }
    
    /// Receive messages over the established channel
    ///
    /// - Returns: the iteratable `AsyncThrowingStream` contains `FusionResult`
    public nonisolated func receive() -> AsyncThrowingStream<FusionResult, Error> {
        return stream
    }
}

// MARK: - Private API Extension -

private extension FusionChannel {
    /// Create message frame with `FusionFramer` and send it over the channel
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    private func processing<Message: FusionMessage>(with message: Message) async throws -> Void {
        guard let channel, let message = message as? FusionFrame else { return }
        let frame = try framer.create(message: message)
        for chunk in frame.chunks(of: parameters.leverage) { try await channel.send(chunk); continuation.yield(.report(.init(outbound: chunk.count))) }
    }
    
    /// Receive message frames over the channel and parse it with `FusionFramer`
    ///
    /// Exposes the parsed `FusionMessage` and the `FusionReport`
    private func processing() async throws -> Void {
        while !Task.isCancelled { guard let channel else { return }
            let (data, _) = try await channel.receive(atMost: parameters.leverage.rawValue)
            continuation.yield(.report(.init(inbound: data.count)))
            let messages = try await self.framer.parse(data: data)
            for message in messages { continuation.yield(.message(message)) }
        }
    }
}
