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
    public let size: FusionSize
    public let leverage: FusionLeverage
    
    /// The configurable `FusionParameters`
    ///
    /// - Parameters:
    ///   - parameters: the underlying `NWParameters`
    ///   - priority: the `TaskPriority` for the connection
    ///   - size: the `FusionSize` to limit frame size
    ///   - leverage: receive connection leverage `FusionLeverage`
    public init(with parameters: NWParameters = .tcp, priority: TaskPriority = .userInitiated, size: FusionSize = .medium, leverage: FusionLeverage = .high) {
        self.parameters = parameters
        self.priority = priority
        self.size = size
        self.leverage = leverage
    }
}
