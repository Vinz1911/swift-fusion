//
//  FusionFramer.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal final class FusionFramer: FusionFramerProtocol, @unchecked Sendable {
    private var buffer: DispatchData = .empty
    
    /// Clear the message buffer
    ///
    /// Current message buffer will be cleared
    internal func reset() -> Void {
        buffer = .empty
    }
    
    /// Create a `FusionMessage` conform frame
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    /// - Returns: the message frame as `Data`
    internal func create<T: FusionMessage>(message: T) throws -> Data {
        let total = message.raw.count + FusionConstants.header.rawValue
        guard total <= FusionConstants.frame.rawValue else { throw FusionFramerError.writeBufferOverflow }
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FusionConstants.header.rawValue).endian)
        frame.append(message.raw)
        return frame
    }
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: the `DispatchData` which holds the `FusionMessage`
    /// - Returns: a collection of `FusionMessage`s and `Error`
    internal func parse(data: DispatchData) throws -> [FusionMessage] {
        var messages: [FusionMessage] = []; buffer.append(data); guard var length = buffer.extractLength() else { return .init() }
        guard buffer.count <= FusionConstants.frame.rawValue else { throw FusionFramerError.readBufferOverflow }
        guard buffer.count >= FusionConstants.header.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let opcode = buffer.first else { throw FusionFramerError.parsingFailed }
            guard let payload = buffer.extractPayload(length: length) else { throw FusionFramerError.parsingFailed }
            
            switch opcode {
            case FusionOpcodes.binary.rawValue: messages.append(payload)
            case FusionOpcodes.ping.rawValue: messages.append(UInt16(payload.count))
            case FusionOpcodes.text.rawValue: messages.append(String(bytes: payload, encoding: .utf8) ?? .init())
            default: throw FusionFramerError.unexpectedOpcode }
            
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) };
            if let extracted = buffer.extractLength() { length = extracted }
        }
        return messages
    }
}
