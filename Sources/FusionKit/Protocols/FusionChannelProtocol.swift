//
//  FusionChannelProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FusionChannelProtocol: Sendable {
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the connected `NWEndpoint`
    ///   - parameters: network framework `FusionParameters`
    init(using endpoint: NWEndpoint, parameters: FusionParameters)
    
    /// Start to establish a new channel
    ///
    /// Set config for `NetworkConnection` and establish new channel
    func start() async throws -> Void
    
    /// Cancel the current channel
    ///
    /// Stops the receiver and cancels the current channel
    func cancel() async -> Void
    
    /// Send messages over the established channel
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    func send<Message: FusionMessage>(message: Message) async -> Void
    
    /// Receive messages over the established channel
    ///
    /// - Returns: the iteratable `AsyncThrowingStream` contains `FusionResult`
    nonisolated func receive() -> AsyncThrowingStream<FusionResult, Error>
}
