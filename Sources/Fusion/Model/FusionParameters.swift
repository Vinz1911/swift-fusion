//
//  FusionParameters.swift
//  Fusion
//
//  Created by Vinzenz Weist on 26.11.25.
//  Copyright © 2025 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - Parameters -

@frozen
public struct FusionParameters: FusionParametersProtocol, Sendable {
    public let parameters: NWParameters
    public let priority: TaskPriority
    public let ceiling: FusionCeiling
    public let leverage: FusionLeverage
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - parameters: the underlying `NWParameters`
    ///   - priority: the `TaskPriority` for the connection
    ///   - ceiling: the `FusionCeiling` to limit frame size
    ///   - leverage: the `FusionLeverage` to limit data slices
    public init(with parameters: NWParameters = .tcp, priority: TaskPriority = .userInitiated, ceiling: FusionCeiling = .medium, leverage: FusionLeverage = .high) {
        self.parameters = parameters
        self.priority = priority
        self.ceiling = ceiling
        self.leverage = leverage
    }
}
