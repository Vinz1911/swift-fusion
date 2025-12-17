//
//  FusionStatic.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FusionSize` to limit frame size
public enum FusionSize: Sendable {
    case low
    case medium
    case high
    case custom(UInt32)
    
    /// The `FusionSize` raw value
    var rawValue: UInt32 { switch self { case .low: 0x400000 case .medium: 0x800000 case .high: 0x1000000 case .custom(let size): size } }
}

// MARK: - Message Flow Control -

/// The `FusionStatic` for protocol constants
enum FusionStatic: Int, Sendable {
    case opcode = 0x1
    case header = 0x5
    case total  = 0xFFFFFFFF
}

/// The `FusionOpcode` for the type classification
enum FusionOpcode: UInt8, Sendable {
    case string = 0x1
    case data   = 0x2
    case uint16 = 0x3
    
    /// The `FusionOpcode`type mapping
    var type: any FusionFrame.Type { switch self { case .string: String.self case .data: Data.self case .uint16: UInt16.self } }
}

// MARK: - Receive Leverage -

/// The `NetworkConnection` receive connection leverage
@frozen
public enum FusionLeverage: Int, Sendable {
    case low     = 0x2000
    case medium  = 0x4000
    case high    = 0x8000
    case extreme = 0x10000
}
