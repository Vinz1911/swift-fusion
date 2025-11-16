//
//  FusionMessage.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

/// The `FusionMessage` protocol for message compliance
public protocol FusionMessage: Sendable {
    var opcode: UInt8 { get }
    var raw: Data { get }
}

/// Conformance to protocol `FusionMessage`
extension UInt16: FusionMessage {
    public var opcode: UInt8 { FusionOpcodes.ping.rawValue }
    public var raw: Data { Data(count: Int(self)) }
}

/// Conformance to protocol `FusionMessage`
extension String: FusionMessage {
    public var opcode: UInt8 { FusionOpcodes.text.rawValue }
    public var raw: Data { Data(self.utf8) }
}

/// Conformance to protocol `FusionMessage`
extension Data: FusionMessage {
    public var opcode: UInt8 { FusionOpcodes.binary.rawValue }
    public var raw: Data { self }
}
