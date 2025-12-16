//
//  FusionParametersProtocol.swift
//  Fusion
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
    
    /// The service class `DispatchQoS`
    var qos: DispatchQoS { get set }
    
    /// The `FusionLeverage` paramter for `.maximumLength:`
    var leverage: FusionLeverage { get set }
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tcp: underlying channel specific `NWProtocolTCP.Options`
    ///   - tls: underlying channel specific `NWProtocolTLS.Options`
    ///   - qos: dispatch queue qos `DispatchQoS`
    ///   - leverage: receive channel leverage `FusionLeverage`
    init(tcp: NWProtocolTCP.Options, tls: NWProtocolTLS.Options?, qos: DispatchQoS, leverage: FusionLeverage)
}
