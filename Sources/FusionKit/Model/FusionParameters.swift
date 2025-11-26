//
//  FusionParameters.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 26.11.25.
//

import Foundation
import Network

// MARK: - Parameters -

@frozen
public struct FusionParameters: FusionParametersProtocol, Sendable {
    public var network: NWParameters
    public var qos: DispatchQoS
    public var weight: FusionWeight
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - network: underlying channel specific `NWParameters`
    ///   - qos: dispatch queue qos `DispatchQoS`
    ///   - weight: receive channel weight `FusionWeight`
    public init(using network: NWParameters = .tcp, qos: DispatchQoS = .userInteractive, weight: FusionWeight = .medium) {
        self.network = network
        self.qos = qos
        self.weight = weight
    }
}
