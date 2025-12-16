//
//  FusionParametersProtocol.swift
//  Fusion
//
//  Created by Vinzenz Weist on 26.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public protocol FusionParametersProtocol: Sendable {
    /// underlying connection specific `NWProtocolTLS.Options`
    var tls: NWProtocolTLS.Options? { get set }
    
    /// underlying connection specific `NWProtocolTCP.Options`
    var tcp: NWProtocolTCP.Options { get set }
    
    /// the `TaskPriority` for the connection
    var priority: TaskPriority { get set }
    
    /// receive connection leverage `FusionLeverage`
    var leverage: FusionLeverage { get set }
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tls: the underlying connection specific `NWProtocolTLS.Options`
    ///   - tcp: the underlying connection specific `NWProtocolTCP.Options`
    ///   - serviceClass: the `NWParameters.ServiceClass`
    ///   - priority: the `TaskPriority` for the connection
    ///   - leverage: receive connection leverage `FusionLeverage`
    init(tls: NWProtocolTLS.Options?, tcp: NWProtocolTCP.Options, serviceClass: NWParameters.ServiceClass, priority: TaskPriority, leverage: FusionLeverage)
}
