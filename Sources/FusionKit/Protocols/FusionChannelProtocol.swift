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
    ///   - endpoint: the `NWEndpoint`
    ///   - parameters: the configurable `FusionParameters`
    init(using endpoint: NWEndpoint, parameters: FusionParameters) throws
    
    /// Start to establish a new channel
    ///
    /// Establish a new `FusionChannel` to a compatible booststrap
    func start() -> Void
    
    /// Cancel an active channel
    ///
    /// The current active `FusionChannel` will be terminated
    func cancel() -> Void
    
    /// Send a `FusionMessage` to a connected bootstraped
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    func send<T: FusionMessage>(message: T) -> Void
    
    /// Receive a message from a connected bootstraped
    ///
    /// - Parameter completion: contains `FusionResult` generic message typ
    func receive(_ completion: @Sendable @escaping (FusionResult) -> Void) -> Void
}
