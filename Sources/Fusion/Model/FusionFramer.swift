//
//  FusionFramer.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

actor FusionFramer: FusionFramerProtocol, Sendable {
    private var buffer: Data = .init()
    
    /// Clear the internal `Data` message buffer
    ///
    /// Current message buffer will be cleared
    func clear() async -> Void { self.buffer.removeAll() }
    
    /// Create a `FusionMessage` conform to the `FusionFrame`
    ///
    /// - Parameter message: the `FusionMessage` conform to the `FusionFrame`
    /// - Returns: the message frame as `Data`
    nonisolated func create<Message: FusionFrame>(message: Message) throws(FusionFramerError) -> Data {
        guard message.size <= FusionStatic.total.rawValue else { throw .outbound }
        var frame = Data(); frame.append(message.opcode)
        frame.append(UInt32(message.size).endian)
        frame.append(message.encode); return frame
    }
    
    /// Parse a `FusionMessage` conform to the `FusionFrame`
    ///
    /// - Parameters:
    ///   - data: the `Data` slice of the `FusionMessage` conform to the `FusionFrame`
    ///   - size: the inbound buffer size limit from `FusionSize`
    /// - Returns: a collection of `FusionMessage`s conform to the `FusionFrame` and `Error`
    func parse(data: Data, size: FusionSize = .custom(.max)) async throws(FusionFramerError) -> [FusionFrame] {
        var messages: [FusionFrame] = []; buffer.append(data)
        guard buffer.count <= FusionStatic.total.rawValue, buffer.count <= size.rawValue else { throw .inbound }
        guard buffer.count >= FusionStatic.header.rawValue else { return .init() }
        while let length = try buffer.length(), buffer.count >= length && length != .zero {
            guard let opcode = buffer.first else { throw .opcode }
            guard let message = buffer.decode(with: opcode, from: length) else { throw .decode }
            buffer.removeSubrange(.zero..<Int(length)); messages.append(message)
        }
        return messages
    }
}
