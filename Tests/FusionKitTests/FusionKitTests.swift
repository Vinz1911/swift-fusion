//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Testing
import Foundation
@testable import FusionKit

@Suite("FusionKit Tests")
struct FusionKitTests {
    
    @Test("Send String")
    func sendString() async throws {
        let connection = try FusionConnection(host: "de0.weist.org", port: 7878)
        await connection.start()
        try await connection.send(message: "500")
        try await connection.receive { message, bytes in
            var reference: Int = .zero
            if let message = message as? Data { reference = message.count }
            print("MESSAGE: \(message)")
            #expect(reference == 10000)
            await connection.cancel()
        }
    }
    
    @Test("Send Data")
    func sendData() async throws {
        let connection = try FusionConnection(host: "de0.weist.org", port: 7878)
        await connection.start()
        try await connection.send(message: Data(count: 10000))
        try await connection.receive { message, bytes in
            var reference: String = .init()
            if let message = message as? String {
                reference = message
                //#expect(reference == "10000")
                print("MESSAGE: \(message)")
            }
            await connection.cancel()
        }
        try await Task.sleep(for: .seconds(1000))
    }
    /*
    @Test("Multi Message")
    func sendMultiple() async throws {
        let connection = try FKConnection(host: "localhost", port: 7878)
        try await connection.start()
        try await connection.send(message: "1000000")
        try await connection.receive { messages in
            if let _ = messages as? Data { try await connection.send(message: "1000000") }
        }
    }
    */
    
    @Test("Parse Message")
    func parseMessage() async throws {
        let framer = FusionFramer(); var count: Int = .zero
        var message = try await framer.create(message: "FluxCapacitor!")

        var buffer = Data()
        for length in stride(from: Int(message[4]), through: 6, by: -1) {
            var copy = message; copy[4] = UInt8(length); buffer.append(copy)
            if copy.count > .zero { message.removeLast(); }
            count += 1
        }
        
        var parsed: [String] = []
        let messages = try await framer.parse(data: buffer)
        for message in messages {
            if let message = message as? String { parsed.append(message) }
        }
        #expect(count == parsed.count)
    }
}
