//
//  FusionParameters.swift
//  Fusion
//
//  Created by Vinzenz Weist on 26.11.25.
//

import Foundation
import Network

// MARK: - Parameters -

@frozen
public struct FusionParameters: FusionParametersProtocol, Sendable {
    public var tcp: NWProtocolTCP.Options
    public var tls: NWProtocolTLS.Options?
    public var qos: DispatchQoS
    public var leverage: FusionLeverage
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tcp: underlying channel specific `NWProtocolTCP.Options`
    ///   - tls: underlying channel specific `NWProtocolTLS.Options`
    ///   - qos: dispatch queue qos `DispatchQoS`
    ///   - leverage: receive channel leverage `FusionLeverage`
    public init(tcp: NWProtocolTCP.Options = .init(), tls: NWProtocolTLS.Options? = nil, qos: DispatchQoS = .userInteractive, leverage: FusionLeverage = .medium) {
        self.tcp = tcp
        self.tls = tls
        self.qos = qos
        self.leverage = leverage
    }
}
