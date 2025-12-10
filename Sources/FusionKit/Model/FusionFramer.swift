//
//  FusionFramer.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

actor FusionFramer: FusionFramerProtocol {
    private var buffer: Data = .init()
    
    /// Clear the internal `Data` message buffer
    ///
    /// Current message buffer will be cleared
    func clear() async -> Void { self.buffer.removeAll() }
    
    /// Create a `FusionMessage` conform to the `FusionFrame`
    ///
    /// - Parameter message: the `FusionMessage` conform to the `FusionFrame`
    /// - Returns: the message frame as `Data`
    nonisolated func create<Message: FusionFrame>(message: Message) throws -> Data {
        guard message.size <= FusionPacket.payload.rawValue else { throw FusionFramerError.outputBufferOverflow }
        var frame = Data(); frame.append(message.opcode); frame.append(UInt32(message.size).endian); frame.append(message.encode)
        return frame
    }
    
    /// Parse a `FusionMessage` conform to the `FusionFrame`
    ///
    /// - Parameter data: the `Data` slice of the `FusionMessage` conform to the `FusionFrame`
    /// - Returns: a collection of `FusionMessage`s conform to the `FusionFrame` and `Error`
    func parse(data: Data) async throws -> [FusionFrame] {
        var messages: [FusionFrame] = []; buffer.append(data); guard var length = buffer.length() else { return .init() }
        guard buffer.count <= FusionPacket.payload.rawValue else { throw FusionFramerError.inputBufferOverflow }
        guard buffer.count >= FusionPacket.header.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let opcode = buffer.first else { throw FusionFramerError.loadOpcodeFailed }
            guard let message = buffer.decode(with: opcode, from: length) else { throw FusionFramerError.decodeMessageFailed }
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) }
            if let index = buffer.length() { length = index }; messages.append(message)
        }
        return messages
    }
}
