//
//  FusionParametersProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 26.11.25.
//

import Foundation
import Network

public protocol FusionParametersProtocol: Sendable {
    /// The underlying `NWParameters`
    var network: NWParameters { get set }
    
    /// The service class `DispatchQoS`
    var qos: DispatchQoS { get set }
    
    /// The `FusionWeight` paramter for `.maximumLength:`
    var weight: FusionWeight { get set }
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - network: underlying channel specific `NWParameters`
    ///   - qos: dispatch queue qos `DispatchQoS`
    ///   - weight: receive channel weight `FusionWeight`
    init(using network: NWParameters, qos: DispatchQoS, weight: FusionWeight)
}
