//
//  FusionOpcodes.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

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
