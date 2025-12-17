//
//  FusionFramer.swift
//  Fusion
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
    /// - Returns: the result type as tuple `(Data, Error)`
    internal func create<T: FusionMessage>(message: T) -> (Data, Error?) {
        let total = message.raw.count + FusionConstants.header.rawValue
        guard total <= FusionConstants.frame.rawValue else { return (.init(), FusionFramerError.writeBufferOverflow) }
        
        var frame = Data()
        frame.append(message.opcode)
        frame.append(UInt32(message.raw.count + FusionConstants.header.rawValue).endian)
        frame.append(message.raw)
        return (frame, nil)
    }
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: the `DispatchData` which holds the `FusionMessage`
    /// - Returns: the result type as tuple `([FusionMessage], Error?)`
    internal func parse(data: DispatchData) -> ([FusionMessage], Error?) {
        var messages: [FusionMessage] = []; buffer.append(data); guard var length = buffer.extractLength() else { return (.init(), nil) }
        guard buffer.count <= FusionConstants.frame.rawValue else { return (.init(), FusionFramerError.readBufferOverflow) }
        guard buffer.count >= FusionConstants.header.rawValue, buffer.count >= length else { return (.init(), nil) }
        while buffer.count >= length && length != .zero {
            guard let opcode = buffer.first else { return (.init(), FusionFramerError.parsingFailed) }
            guard let payload = buffer.extractPayload(length: length) else { return (.init(), FusionFramerError.parsingFailed) }
            
            switch opcode {
            case FusionOpcodes.binary.rawValue: messages.append(payload)
            case FusionOpcodes.ping.rawValue: messages.append(UInt16(payload.count))
            case FusionOpcodes.text.rawValue: messages.append(String(bytes: payload, encoding: .utf8) ?? .init())
            default: return (.init(), FusionFramerError.unexpectedOpcode) }
            
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) };
            if let extracted = buffer.extractLength() { length = extracted }
        }
        return (messages, nil)
    }
}
