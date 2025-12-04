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

    /// Creates an instance of `FusionFramer`.
    ///
    /// The `FusionFramer` implements the **Fusion Framing Protocol (FFP)** —
    /// a fast and lightweight message framing protocol that supports both
    /// `ByteBuffer`- and `String`-based messages.
    ///
    /// - Parameter buffer: the initialize buffer as `Data`
    init(buffer: Data = .init()) { self.buffer = buffer }

    /// Create a `FusionMessage` conform to the `FusionProtocol`
    ///
    /// - Parameter message: the `FusionMessage` conform to the `FusionProtocol`
    /// - Returns: the message frame as `Data`
    nonisolated func create<Message: FusionProtocol>(message: Message) throws -> Data {
        let total = message.encode.count + FusionConstants.header.rawValue
        guard total <= FusionConstants.frame.rawValue else { throw FusionFramerError.writeBufferOverflow }
        var frame = Data(); frame.append(message.opcode); frame.append(message.size); frame.append(message.encode)
        return frame
    }

    /// Parse a `FusionMessage` conform to the `FusionProtocol`
    ///
    /// - Parameter data: the `Data` slice of the `FusionMessage` conform to the `FusionProtocol`
    /// - Returns: a collection of `FusionMessage`s conform to the `FusionProtocol` and `Error`
    func parse(data: Data) async throws -> [FusionProtocol] {
        var messages: [FusionProtocol] = []; buffer.append(data); guard var length = buffer.length() else { return .init() }
        guard buffer.count <= FusionConstants.frame.rawValue else { throw FusionFramerError.readBufferOverflow }
        guard buffer.count >= FusionConstants.header.rawValue, buffer.count >= length else { return .init() }
        while buffer.count >= length && length != .zero {
            guard let opcode = buffer.first else { throw FusionFramerError.parsingFailed }
            guard let payload = buffer.payload(from: length) else { throw FusionFramerError.parsingFailed }
            guard let message = payload.decode(from: opcode) else { throw FusionFramerError.parsingFailed }
            if buffer.count >= length { buffer = buffer.subdata(in: .init(length)..<buffer.count) }
            if let extracted = buffer.length() { length = extracted }; messages.append(message)
        }
        return messages
    }
}
