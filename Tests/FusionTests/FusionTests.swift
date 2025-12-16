//
//  FusionTests.swift.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Testing
import Foundation
@testable import Fusion

@Suite("Fusion Tests")
struct FusionTests {
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
    
    /// Framer error validation
    @Test("Famer Error")
    func framerError() async throws {
        let framer = FusionFramer()
        let malformed = Data([1, 0, 0, 0, 1, 0, 0, 0, 10, 80, 97, 115, 115, 33])
        let invalid = Data([0x1, 0x0, 0x0, 0x0, 0x6, 0xFF])
        let breakSync = Data([0x01, 0x00, 0x00, 0x00, 0x01, 0xAA, 0x02, 0x00, 0x00, 0x00, 0x01, 0xBB])
        let zeroLen = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(throws: FusionFramerError.outbound) { try framer.create(message: Data(count: Int(UInt32.max))) }
        await #expect(throws: FusionFramerError.inbound) { try await framer.parse(data: Data(count: Int(UInt32.max) + 1)) }
        await #expect(throws: FusionFramerError.invalid) { await framer.clear(); let _ = try await framer.parse(data: zeroLen) }
        await #expect(throws: FusionFramerError.decode) { await framer.clear(); let _ = try await framer.parse(data: invalid) }
        await #expect(throws: FusionFramerError.decode) { await framer.clear(); let _ = try await framer.parse(data: malformed) }
        await #expect(throws: FusionFramerError.decode) { await framer.clear(); let _ = try await framer.parse(data: breakSync) }
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
    
    /// Robustness check
    @Test("Parse Incomplete") func parseIncomplete() async throws {
        let framer = FusionFramer(); var messages: [String] = []
        var frames = try framer.create(message: "Pass!")
        let slices: [Data] = [Data([1, 0, 0, 0]), Data([10, 80, 97]), Data([115, 115, 33])]
        
        frames.append(contentsOf: slices[0])
        for message in try await framer.parse(data: frames) { if let message = message as? String { messages.append(message) } }
        
        for _ in try await framer.parse(data: slices[1]) { /* nothing to append */ }
        
        frames.append(contentsOf: slices[2])
        for message in try await framer.parse(data: slices[2]) { if let message = message as? String { messages.append(message) } }
        #expect(messages[0] == messages[1])
    }
    
    /// Zer0 payload
    @Test("Zero Payload")
    func zeroPayload() async throws {
        let framer = FusionFramer()
        do {
            let frame = try framer.create(message: Data())
            let parsed = try await framer.parse(data: frame)
            #expect(parsed.count == 1); #expect(parsed[0] is Data); #expect((parsed[0] as? Data)?.count == 0)
        }
        await framer.clear()
        do {
            let frame = try framer.create(message: "")
            let parsed = try await framer.parse(data: frame)
            #expect(parsed.count == 1); #expect(parsed[0] is String); #expect((parsed[0] as? String) == "")
        }
    }
}

// MARK: - Private API Extension -

extension FusionTests {
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
