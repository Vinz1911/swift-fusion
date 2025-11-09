//
//  FKConnectionProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FKConnectionProtocol: Sendable {
    /// The `FKConnection` is a custom network framing protocol and implements the `Fusion Framing Protocol`.
    /// It's build on top of the `Network` framework standard library. A fast and lightweight Framing Protocol
    /// allows to transmit data as fast as possible and allows a more fine grained control over the network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    init(host: String, port: UInt16) throws
    
    /// Start a connection
    ///
    /// - Returns: non returning
    func start() async throws -> Void
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    func cancel() async throws -> Void
    
    /// The current state
    ///
    /// - Returns: current `TCP.State`
    func state() async -> NetworkChannel<TCP>.State?
    
    /// Send a message compliant to `FKMessage`
    ///
    /// - Parameter message: a `FKMessage` compliant message
    func send<Message: FKMessage>(message: Message) async throws -> Void
    
    /// Receive a message compliant to `FKMessage`
    ///
    /// - Parameter completion: async completion block
    func receive(_ completion: (@Sendable (FKMessage) async throws -> Void)?) async throws -> Void
}
