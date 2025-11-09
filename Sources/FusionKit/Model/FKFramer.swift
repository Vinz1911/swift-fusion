//
//  FKFramer.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal actor FKFramer: FKFramerProtocol, Sendable {
    private var buffer: Data
    
    /// Create instance of `FKFramer`
    ///
    /// The `FKFramer` represents the fusion framing protocol.
    /// This is a very fast and lightweight message framing protocol that supports `String` and `Data` based messages.
    /// It also supports `UInt16` for ping based transfer responses.
    /// The protocol's overhead per message is only `0x5` bytes, resulting in high performance.
    ///
    /// This protocol is based on a standardized Type-Length-Value Design Scheme.
    internal init() {
        self.buffer = Data()
    }
    
    /// Create a protocol conform message frame
    ///
    /// - Parameter message: generic type which conforms to `Data` and `String`
    /// - Returns: generic Result type returning data and possible error
    internal func create<T: FKMessage>(message: T) async throws -> Data {
        guard message.raw.count <= FKConstants.frame.rawValue - FKConstants.control.rawValue else { throw FKError.writeBufferOverflow }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FKConstants.control.rawValue).bigEndianBytes)
        frame.append(message.raw)
        return frame
    }
    
    /// Parse a protocol conform message frame
    ///
    /// - Parameters:
    ///   - data: the data which should be parsed
    ///   - completion: completion block returns generic Result type with parsed message and possible error
    internal func parse(data: Data) async throws -> [FKMessage] {
        var messages: [FKMessage] = []; buffer.append(data); var length = buffer.length; if length <= .zero { return .init() }
        guard buffer.count <= FKConstants.frame.rawValue else { throw FKError.readBufferOverflow }
        guard buffer.count >= FKConstants.control.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let bytes = buffer.payload() else { throw FKError.parsingFailed }
            switch buffer.first {
            case FKOpcodes.binary.rawValue: messages.append(bytes)
            case FKOpcodes.ping.rawValue: messages.append(UInt16(bytes.count))
            case FKOpcodes.text.rawValue: if let message = String(bytes: bytes, encoding: .utf8) { messages.append(message) }
            default: throw FKError.unexpectedOpcode }
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) }; length = buffer.length
        }
        return messages
    }
}
