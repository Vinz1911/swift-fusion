//
//  FusionOpcodes.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Receive Weight -

/// The `NWConnection` receive channel leverage
@frozen
public enum FusionLeverage: Int, Sendable {
    case low     = 0x2000
    case medium  = 0x4000
    case high    = 0x8000
    case extreme = 0x10000
}

// MARK: - Message Flow Control -

/// The `FusionOpcodes` for the frame header
internal enum FusionOpcodes: UInt8, Sendable {
    case none   = 0x0
    case text   = 0x1
    case binary = 0x2
    case ping   = 0x3
}

/// The `FusionConstants` for protocol limits
internal enum FusionConstants: Int, Sendable {
    case opcode = 0x1
    case header = 0x5
    case frame  = 0xFFFFFFFF
}
