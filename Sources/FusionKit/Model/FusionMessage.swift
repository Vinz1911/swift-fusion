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
    var size: UInt32 { get }
    var encode: Data { get }
    static func decode(from payload: Data) -> FusionProtocol?
}

// MARK: - Fusion Message Extensions -

/// Conformance to protocol `FusionProtocol` and `FusionMessage`
extension UInt16: FusionProtocol {
    var opcode: UInt8 { FusionOpcode.uint16.rawValue }
    var size: UInt32 { UInt32(self.encode.count + FusionFrame.header.rawValue) }
    var encode: Data { Data(count: Int(self)) }
    static func decode(from payload: Data) -> FusionProtocol? { Self(payload.count) }
}

/// Conformance to protocol `FusionProtocol` and `FusionMessage`
extension String: FusionProtocol {
    var opcode: UInt8 { FusionOpcode.string.rawValue }
    var size: UInt32 { UInt32(self.encode.count + FusionFrame.header.rawValue) }
    var encode: Data { Data(self.utf8) }
    static func decode(from payload: Data) -> FusionProtocol? { Self(bytes: payload, encoding: .utf8) }
}

/// Conformance to protocol `FusionProtocol` and `FusionMessage`
extension Data: FusionProtocol {
    var opcode: UInt8 { FusionOpcode.data.rawValue }
    var size: UInt32 { UInt32(self.encode.count + FusionFrame.header.rawValue) }
    var encode: Data { self }
    static func decode(from payload: Data) -> FusionProtocol? { payload }
}
