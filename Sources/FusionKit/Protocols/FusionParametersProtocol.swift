//
//  FusionParametersProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 26.11.25.
//

import Foundation
import Network

public protocol FusionParametersProtocol: Sendable {
    /// underlying channel specific `NWProtocolTCP.Options`
    var tcp: NWProtocolTCP.Options { get set }
    
    /// underlying channel specific `NWProtocolTLS.Options`
    var tls: NWProtocolTLS.Options? { get set }
    
    /// the `TaskPriority` for the channel
    var priority: TaskPriority { get set }
    
    /// receive channel leverage `FusionLeverage`
    var leverage: FusionLeverage { get set }
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tcp: underlying channel specific `NWProtocolTCP.Options`
    ///   - tls: underlying channel specific `NWProtocolTLS.Options`
    ///   - priority: the `TaskPriority` for the channel
    ///   - leverage: receive channel leverage `FusionLeverage`
    init(tcp: NWProtocolTCP.Options, tls: NWProtocolTLS.Options?, priority: TaskPriority, leverage: FusionLeverage)
}
