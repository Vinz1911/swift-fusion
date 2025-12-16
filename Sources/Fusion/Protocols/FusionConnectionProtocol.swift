//
//  FusionConnectionProtocol.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FusionConnectionProtocol: Sendable {
    /// The `FusionConnection` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the connected `NWEndpoint`
    ///   - parameters: network framework `FusionParameters`
    init(using endpoint: NWEndpoint, parameters: FusionParameters)
    
    /// Start to establish a new connection
    ///
    /// Set config for `NetworkConnection` and establish new connection
    func start() async throws -> Void
    
    /// Cancel the current connection
    ///
    /// Stops the receiver and cancels the current connection
    func cancel() async -> Void
    
    /// Send messages over the established connection
    ///
    /// - Parameter message: the message conform to `FusionMessage`
    func send<Message: FusionMessage>(message: Message) async throws -> Void
    
    /// Receive messages over the established connection
    ///
    /// - Returns: the iteratable `AsyncThrowingStream` contains `FusionResult`
    nonisolated func receive() -> AsyncThrowingStream<FusionResult, Error>
}
