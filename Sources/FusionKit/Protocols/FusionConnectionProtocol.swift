//
//  FusionConnectionProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FusionConnectionProtocol: Sendable {
    /// The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    init(host: String, port: UInt16, parameters: NWParameters) throws
    
    /// Start a connection
    ///
    /// - Returns: non returning
    func start() async throws -> Void
    
    /// Cancel the current connection
    ///
    /// - Returns: non returning
    func cancel() async -> Void
    
    /// Send messages to a connected host
    ///
    /// - Parameter message: generic type takes `String`, `Data` and `UInt16` based messages
    func send<T: FusionMessage>(message: T) async throws -> Void
    /// Receive a message from a connected host
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionReport` generic message typ
    func receive(_ completion: @Sendable @escaping (FusionMessage?, FusionReport?) async throws -> Void) async throws -> Void
}
