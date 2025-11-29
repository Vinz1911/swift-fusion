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
    let connection = try? FusionChannel(host: "de0.weist.org", port: 7878)
    
    /// Send `String` message
    @Test("Send String") func sendString() async throws {
        try await performTransmission(message: "16384")
    }
    
    /// Send `Data` message
    @Test("Send Data") func sendData() async throws {
        try await performTransmission(message: Data(count: 16384))
    }
    
    /// Send `UInt16` message
    @Test("Send UInt") func sendUInt() async throws {
        try await performTransmission(message: UInt16(16384))
    }
    
    /// Create + parse with `FusionFramer`
    @Test("Parse Message") func parseMessage() async throws {
        let framer = FusionFramer(); var frames: Data = .init()
        var created: [FusionMessage] = .init(), parsed: [FusionMessage] = .init()
        
        created.append("Hello World! 🌍")
        created.append(Data(count: 16384))
        created.append(UInt16.max)
        
        frames.append(try await framer.create(message: created[0]))
        frames.append(try await framer.create(message: created[1]))
        frames.append(try await framer.create(message: created[2]))
        
        let messages = try await framer.parse(data: frames)
        for message in messages { parsed.append(message) }
        
        if let create = created[0] as? String, let parse = parsed[0] as? String { print("🟣 Created String: \(create), Parsed String: \(parse)"); #expect(create == parse) }
        if let create = created[1] as? Data, let parse = parsed[1] as? Data { print("🟣 Created Data: \(create.count), Parsed Data: \(parse.count)"); #expect(create == parse) }
        if let create = created[2] as? UInt16, let parse = parsed[2] as? UInt16 { print("🟣 Created UInt16: \(create), Parsed UInt16: \(parse)"); #expect(create == parse) }
    }
}

// MARK: - Private API -

extension FusionKitTests {
    /// Perform Send + Receive
    ///
    /// - Parameter message: message that conforms to `FusionMessage`
    private func performTransmission<T: FusionMessage>(message: T) async throws {
        guard let connection else { throw FusionChannelError.establishmentFailed }
        try await connection.start()
        let task = Task {
            for try await result in connection.receive() {
                guard case .message(let messages) = result else { continue }
                if message is String {
                    guard let messages = messages as? Data else { continue }
                    print("🟣 Received Data: \(messages.count)")
                    #expect(messages.count == Int(message as! String))
                }
                if message is Data {
                    guard let messages = messages as? String else { continue }
                    print("🟣 Received String: \(messages)")
                    #expect(messages == "\((message as! Data).count)")
                }
                if message is UInt16 {
                    guard let messages = messages as? UInt16 else { continue }
                    print("🟣 Received UInt16: \(messages)")
                    #expect(messages == message as! UInt16)
                }
                await connection.cancel()
            }
        }
        try await connection.send(message: message); try await task.value
    }
}
