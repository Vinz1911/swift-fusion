//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import XCTest
@testable import FusionKit

// MARK: - Tests -

class FusionKitTests: XCTestCase, @unchecked Sendable {
    private var channel = FusionChannel(using: .hostPort(host: "de0.weist.org", port: 7878))
    
    /// Initialize Setup
    override func setUp() { super.setUp() }
    
    /// Start test sending single text message
    func testString() { transmit(message: "16384") }
    
    /// Start test sending single binary message
    func testData() { transmit(message: Data(count: 16384)) }
    
    /// Start test sending single ping message
    func testUInt() { transmit(message: UInt16(16384)) }
    
    /// Start test creating and parsing string based message
    func testFramer() { parser() }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// Create a channel and start
    ///
    /// - Parameter test: test case
    private func transmit<T: FusionMessage>(message: T) {
        let exp = XCTestExpectation(description: "FusionKit Send + Receive")
        channel.receive { [weak self] result in guard let self else { return }
            if case .ready = result { channel.send(message: message) }
            if case .failed(let error) = result { XCTFail("failed with error: \(error)")}
            if case .message(let message) = result {
                if case let message as UInt16 = message { XCTAssertEqual(message, UInt16(16384)); print("🟣 UInt16: \(message)"); channel.cancel(); exp.fulfill() }
                if case let message as Data = message { XCTAssertEqual(message.count, Int(16384)); print("🟣 Data: \(message)"); channel.cancel(); exp.fulfill() }
                if case let message as String = message { XCTAssertEqual(message, "16384"); print("🟣 String: \(message)"); channel.cancel(); exp.fulfill() }
            }
        }
        channel.start(); wait(for: [exp], timeout: 7.5)
    }
    
    /// Run the `FusionFramer`
    ///
    /// runs the create + parser from the `FusionFramer`
    private func parser() {
        let framer = FusionFramer(); var frames: Data = .init()
        let messages: [FusionMessage] = ["Hello World! 🌍", Data(count: 8192), UInt16.max]
        
        for message in messages {
            let (frame, error) = framer.create(message: message)
            if let error { XCTFail("Failed with: \(error)") }
            frames.append(frame)
        }
        
        let dispatch = frames.withUnsafeBytes { DispatchData(bytes: $0) }
        let (parser, error) = framer.parse(data: dispatch)
        if let error { XCTFail("Failed with: \(error)") }
        
        for message in parser {
            if case let message as String = message { XCTAssertEqual(messages[0] as! String, message); print("🟣 \(messages[0]) == \(message)") }
            if case let message as Data = message { XCTAssertEqual(messages[1] as! Data, message); print("🟣 \(messages[1]) == \(message)") }
            if case let message as UInt16 = message { XCTAssertEqual(messages[2] as! UInt16, message); print("🟣 \(messages[2]) == \(message)") }
        }
    }
}
