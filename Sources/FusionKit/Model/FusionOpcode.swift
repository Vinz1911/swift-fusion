//
//  FusionOpcode.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Message Flow Control -

/// The `FusionOpcode` for the type classification
enum FusionOpcode: UInt8, Sendable {
    case string = 0x1
    case data   = 0x2
    case uint16 = 0x3
}

/// The `FusionFrame` for protocol constants
enum FusionFrame: Int, Sendable {
    case opcode = 0x1
    case header = 0x5
    case frame  = 0xFFFFFFFF
}

// MARK: - Receive Leverage -

/// The `NetworkConnection` receive channel leverage
@frozen
public enum FusionLeverage: Int, Sendable {
    case low     = 0x2000
    case medium  = 0x4000
    case high    = 0x8000
    case extreme = 0x10000
}
