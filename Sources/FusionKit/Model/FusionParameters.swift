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
    public var tcp: NWProtocolTCP.Options
    public var tls: NWProtocolTLS.Options?
    public var priority: TaskPriority
    public var leverage: FusionLeverage
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - tcp: underlying channel specific `NWProtocolTCP.Options`
    ///   - tls: underlying channel specific `NWProtocolTLS.Options`
    ///   - priority: the `TaskPriority` for the channel
    ///   - leverage: receive channel leverage `FusionLeverage`
    public init(tcp: NWProtocolTCP.Options = .init(), tls: NWProtocolTLS.Options? = nil, priority: TaskPriority = .high, leverage: FusionLeverage = .medium) {
        self.tcp = tcp
        self.tls = tls
        self.priority = priority
        self.leverage = leverage
    }
}
