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
        let connection = try FusionChannel(host: "de0.weist.org", port: 7878)
        try await connection.start()
        let task = Task {
            for try await result in await connection.receive() {
                guard case .message(let message) = result else { return }
                guard let message = message as? Data else { return }
                #expect(message.count == 10000)
                await connection.cancel()
            }
        }
        try await connection.send(message: "10000")
        try await task.value
    }
    
    @Test("Send Data")
    func sendData() async throws {
        let connection = try FusionChannel(host: "de0.weist.org", port: 7878)
        try await connection.start()
        let task = Task {
            for try await result in await connection.receive() {
                guard case .message(let message) = result else { return }
                guard let message = message as? String else { return }
                #expect(message == "10000")
                await connection.cancel()
            }
        }
        try await connection.send(message: Data(count: 10000))
        try await task.value
    }
    
    @Test("Multi Message")
    func sendMultiple() async throws {
        let connection = try FusionChannel(host: "de0.weist.org", port: 7878)
        try await connection.start()
        let task = Task {
            for try await result in await connection.receive() {
                if case .report(let report) = result { print(report.inbound) }
                guard case .message(let message) = result else { continue }
                guard let message = message as? Data else { continue }
                try await connection.send(message: "1000000")
            }
        }
        try await connection.send(message: "1000000")
        try await task.value
    }
    
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
