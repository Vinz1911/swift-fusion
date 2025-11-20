//
//  FusionLinkProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FusionLinkProtocol: Sendable {
    /// The `FusionState` update values
    var onStateUpdate: (@Sendable (FusionState) -> Void) { get set }
    
    /// The `FusionLink` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    init(host: String, port: UInt16, parameters: NWParameters, qos: DispatchQoS) throws
    
    /// Start to establish a new link
    ///
    /// Establish a new `FusionLink` to a compatible booststrap
    func start() -> Void
    
    /// Cancel an active link
    ///
    /// The current active `FusionLink` will be terminated
    func cancel() -> Void
    
    /// Send a `FusionMessage` to a linked bootstraped
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    func send<T: FusionMessage>(message: T) -> Void
    
    /// Receive a message from a linked bootstraped
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionReport` generic message typ
    func receive(_ completion: @Sendable @escaping (FusionMessage?, FusionReport?) -> Void) -> Void
}
