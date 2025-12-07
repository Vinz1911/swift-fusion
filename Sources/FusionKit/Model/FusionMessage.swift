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

/// The `FusionFrame` protocol for message conformance
protocol FusionFrame: FusionMessage {
    var opcode: UInt8 { get }
    var size: UInt64 { get }
    var encode: Data { get }
    static func decode(from payload: Data) -> FusionFrame?
}

// MARK: - Fusion Message Extensions -

/// Conformance to protocol `FusionFrame` and `FusionMessage`
extension UInt16: FusionFrame {
    var opcode: UInt8 { FusionOpcode.uint16.rawValue }
    var size: UInt64 { UInt64(self.encode.count + FusionPacket.header.rawValue) }
    var encode: Data { Data(count: Int(self)) }
    static func decode(from payload: Data) -> FusionFrame? { Self(payload.count) }
}

/// Conformance to protocol `FusionFrame` and `FusionMessage`
extension String: FusionFrame {
    var opcode: UInt8 { FusionOpcode.string.rawValue }
    var size: UInt64 { UInt64(self.encode.count + FusionPacket.header.rawValue) }
    var encode: Data { Data(self.utf8) }
    static func decode(from payload: Data) -> FusionFrame? { Self(bytes: payload, encoding: .utf8) }
}

/// Conformance to protocol `FusionFrame` and `FusionMessage`
extension Data: FusionFrame {
    var opcode: UInt8 { FusionOpcode.data.rawValue }
    var size: UInt64 { UInt64(self.encode.count + FusionPacket.header.rawValue) }
    var encode: Data { self }
    static func decode(from payload: Data) -> FusionFrame? { payload }
}
