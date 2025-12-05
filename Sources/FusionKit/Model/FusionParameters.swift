//
//  FusionParameters.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 26.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - Parameters -

@frozen
public struct FusionParameters: FusionParametersProtocol, Sendable {
    public var tls: NWProtocolTLS.Options?
    public var tcp: NWProtocolTCP.Options
    public var service: NWParameters.ServiceClass
    public var priority: TaskPriority
    public var leverage: FusionLeverage
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tls: the underlying channel specific `NWProtocolTLS.Options`
    ///   - tcp: the underlying channel specific `NWProtocolTCP.Options`
    ///   - service: the `NWParameters.ServiceClass`
    ///   - priority: the `TaskPriority` for the channel
    ///   - leverage: receive channel leverage `FusionLeverage`
    public init(tls: NWProtocolTLS.Options? = nil, tcp: NWProtocolTCP.Options = .init(), service: NWParameters.ServiceClass = .bestEffort, priority: TaskPriority = .userInitiated, leverage: FusionLeverage = .high) {
        self.tcp = tcp
        self.tls = tls
        self.priority = priority
        self.leverage = leverage
        self.service = service
    }
}
