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
    /// the underlying `NWParameters`
    var parameters: NWParameters { get set }
    
    /// the `TaskPriority` for the connection
    var priority: TaskPriority { get set }
    
    /// the maximum parser limit as `UInt32`
    var size: FusionSize { get set }
    
    /// receive connection leverage `FusionLeverage`
    var leverage: FusionLeverage { get set }
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - parameters: the underlying `NWParameters`
    ///   - priority: the `TaskPriority` for the connection
    ///   - size: the `FusionSize` to limit frame size
    ///   - leverage: receive connection leverage `FusionLeverage`
    init(parameters: NWParameters, priority: TaskPriority, size: FusionSize, leverage: FusionLeverage)
}
