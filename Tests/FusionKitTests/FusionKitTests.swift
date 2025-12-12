//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Testing
import Foundation
import Network
@testable import FusionKit

@Suite("FusionKit Tests")
struct FusionKitTests {
    let connection = FusionConnection(using: .hostPort(host: "de0.weist.org", port: 7878))
    
    /// Send `String` message
    @Test("Send String")
    func sendString() async throws {
        try await sendReceive(message: "16384")
    }
    
    /// Send `Data` message
    @Test("Send Data")
    func sendData() async throws {
        try await sendReceive(message: Data(count: 16384))
    }
    
    /// Send `UInt16` message
    @Test("Send UInt")
    func sendUInt() async throws {
        try await sendReceive(message: UInt16(16384))
    }
    
    @Test("Famer Error")
    func framerError() async throws {
        let framer = FusionFramer()
        #expect(throws: FusionFramerError.outputBufferOverflow) { try framer.create(message: Data(count: Int(UInt32.max))) }
        await #expect(throws: FusionFramerError.inputBufferOverflow) { try await framer.parse(data: Data(count: Int(UInt32.max) + 1)) }
        await #expect(throws: FusionFramerError.decodeMessageFailed) { await framer.clear(); let _ = try await framer.parse(data: Data([0x1, 0x0, 0x0, 0x0, 0x6, 0xFF])) }
    }
    
    /// Create + parse with `FusionFramer`
    @Test("Parse Message") func parseMessage() async throws {
        let framer = FusionFramer(); var frames: Data = .init()
        let messages: [FusionMessage] = ["Hello World! 🌍", Data(count: 16384), UInt16.max]
        var parsed: [FusionMessage] = .init()
        
        guard let messages = messages as? [FusionFrame] else { return }
        frames.append(try framer.create(message: messages[0]))
        frames.append(try framer.create(message: messages[1]))
        frames.append(try framer.create(message: messages[2]))
        
        for message in try await framer.parse(data: frames) { parsed.append(message) }
        
        if let message = messages[0] as? String, let parse = parsed[0] as? String { #expect(message == parse) }
        if let message = messages[1] as? Data, let parse = parsed[1] as? Data { #expect(message == parse) }
        if let message = messages[2] as? UInt16, let parse = parsed[2] as? UInt16 { #expect(message == parse) }
    }
}

// MARK: - Private API Extension -

extension FusionKitTests {
    /// Perform Send + Receive
    ///
    /// - Parameter message: message that conforms to `FusionMessage`
    private func sendReceive<Message: FusionMessage>(message: Message) async throws {
        try await connection.start(); try await connection.send(message: message)
        for try await result in connection.receive() {
            guard let messages = result.message else { continue }
            if message is String { if let messages = messages as? Data { #expect(messages.count == Int(message as! String)) } }
            if message is Data { if let messages = messages as? String { #expect(messages == "\((message as! Data).count)") } }
            if message is UInt16 { if let messages = messages as? UInt16 { #expect(messages == message as! UInt16) } }
            await connection.cancel()
        }
    }
}
