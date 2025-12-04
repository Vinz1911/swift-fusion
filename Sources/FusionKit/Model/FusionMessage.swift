//
//  FusionMessage.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Generic Fusion Message Protocol -

/// The public generic `FusionMessage` protocol
///
/// The `FusionMessage` is a generic public message protocol
/// It conforms to `UInt16`, `String` and `Data`
public protocol FusionMessage: Sendable { }

/// The `FusionProtocol` protocol for message conformance
protocol FusionProtocol: FusionMessage {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

// MARK: - Fusion Message Extensions -

/// Conformance to protocol `FusionProtocol` and `FusionMessage`
extension UInt16: FusionProtocol {
    var opcode: UInt8 { FusionOpcodes.ping.rawValue }
    var raw: Data { Data(count: Int(self)) }
}

/// Conformance to protocol `FusionProtocol` and `FusionMessage`
extension String: FusionProtocol {
    var opcode: UInt8 { FusionOpcodes.text.rawValue }
    var raw: Data { Data(self.utf8) }
}

/// Conformance to protocol `FusionProtocol` and `FusionMessage`
extension Data: FusionProtocol {
    var opcode: UInt8 { FusionOpcodes.binary.rawValue }
    var raw: Data { self }
}
