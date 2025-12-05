//
//  FusionParametersProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 26.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FusionParametersProtocol: Sendable {
    /// underlying channel specific `NWProtocolTLS.Options`
    var tls: NWProtocolTLS.Options? { get set }
    
    /// underlying channel specific `NWProtocolTCP.Options`
    var tcp: NWProtocolTCP.Options { get set }
    
    /// the `TaskPriority` for the channel
    var priority: TaskPriority { get set }
    
    /// receive channel leverage `FusionLeverage`
    var leverage: FusionLeverage { get set }
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tls: the underlying channel specific `NWProtocolTLS.Options`
    ///   - tcp: the underlying channel specific `NWProtocolTCP.Options`
    ///   - service: the `NWParameters.ServiceClass`
    ///   - priority: the `TaskPriority` for the channel
    ///   - leverage: receive channel leverage `FusionLeverage`
    init(tls: NWProtocolTLS.Options?, tcp: NWProtocolTCP.Options, service: NWParameters.ServiceClass, priority: TaskPriority, leverage: FusionLeverage)
}
