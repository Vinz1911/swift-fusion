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
    
    /// Create a `FusionMessage` conform to the `FusionProtocol`
    ///
    /// - Parameter message: the `FusionMessage` conform to the `FusionProtocol`
    /// - Returns: the message frame as `Data`
    nonisolated func create<Message: FusionProtocol>(message: Message) throws -> Data {
        guard message.size <= FusionFrame.frame.rawValue else { throw FusionFramerError.writeBufferOverflow }
        var frame = Data(); frame.append(message.opcode); frame.append(message.size.endian); frame.append(message.encode)
        return frame
    }
    
    /// Parse a `FusionMessage` conform to the `FusionProtocol`
    ///
    /// - Parameter data: the `Data` slice of the `FusionMessage` conform to the `FusionProtocol`
    /// - Returns: a collection of `FusionMessage`s conform to the `FusionProtocol` and `Error`
    func parse(data: Data) async throws -> [FusionProtocol] {
        var messages: [FusionProtocol] = []; buffer.append(data); guard var length = buffer.length() else { return .init() }
        guard buffer.count <= FusionFrame.frame.rawValue else { throw FusionFramerError.readBufferOverflow }
        guard buffer.count >= FusionFrame.header.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let opcode = buffer.first else { throw FusionFramerError.parsingFailed }
            guard let payload = buffer.payload(from: length) else { throw FusionFramerError.parsingFailed }
            guard let message = payload.decode(with: opcode) else { throw FusionFramerError.parsingFailed }
            
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) }
            if let extracted = buffer.length() { length = extracted }; messages.append(message)
        }
        return messages
    }
}
