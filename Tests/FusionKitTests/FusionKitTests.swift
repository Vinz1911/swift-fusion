//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import XCTest
@testable import FusionKit

// MARK: - Test Cases -

private enum TestCase {
    case string
    case data
    case ping
}

// MARK: - Tests -

class FusionKitTests: XCTestCase, @unchecked Sendable {
    private var channel = try? FusionChannel(host: "de0.weist.org", port: 7878)
    private var buffer = "50000"
    private let timeout = 10.0
    private let uuid = UUID().uuidString
    private var exp = XCTestExpectation(description: "wait for test to finish...")
    
    /// Set up
    override func setUp() {
        super.setUp()
    }
    
    /// Start test sending single text message
    func testTextMessage() {
        start(test: .string)
    }
    
    /// Start test sending single binary message
    func testBinaryMessage() {
        start(test: .data)
    }
    
    /// Start test sending single ping message
    func testPingMessage() {
        start(test: .ping)
    }
    
    /// Start test sending and cancel
    func testCancel() {
        start(test: .data, cancel: true)
    }
    
    /// Start test creating and parsing string based message
    func testParsingStringMessage() {
        framer()
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// Create a channel and start
    ///
    /// - Parameter test: test case
    private func start(test: TestCase, cancel: Bool = false) {
        guard let channel else { return }
        channel.receive { [weak self] message, bytes, state in
            if cancel { channel.cancel() }
            if let message { self?.assertion(message: message) }
            if let state { self?.onStateUpdate(state: state, channel: channel, test: test) }
        }
        channel.start()
        wait(for: [exp], timeout: timeout)
    }
    
    /// Run framer
    ///
    /// runs `FusionFramer` create and parse
    private func framer() {
        do {
            let framer = FusionFramer()
            let messageString = try framer.create(message: "Hello World! ⭐️")
            let messageData = try framer.create(message: Data(count: 8192))
            let messagePing = try framer.create(message: UInt16.max)
            
            let data = messageString + messageData + messagePing
            let dispatch = data.withUnsafeBytes { DispatchData(bytes: $0) }
            
            var parsed: [Bool] = [false, false, false]
            
            for message in try framer.parse(data: dispatch) {
                if case let message as String = message { print("String: \(message)"); parsed[0] = true }
                if case let message as Data = message { print("Data: \(message.count)"); parsed[1] = true }
                if case let message as UInt16 = message { print("UInt16: \(message)"); parsed[2] = true }
            }
            
            XCTAssertEqual(parsed, [true, true, true]); exp.fulfill()
        } catch {
            XCTFail("failed with error: \(error)")
        }
        wait(for: [exp], timeout: timeout)
    }
    
    /// Handles test routes for messages
    ///
    /// - Parameter message: generic `FusionMessage`
    private func assertion(message: FusionMessage) {
        guard let channel else { return }
        if case let message as UInt16 = message {
            XCTAssertEqual(message, UInt16(buffer))
            channel.cancel(); exp.fulfill()
        }
        if case let message as Data = message {
            XCTAssertEqual(message.count, Int(buffer))
            channel.cancel(); exp.fulfill()
        }
        if case let message as String = message {
            XCTAssertEqual(message, buffer)
            channel.cancel(); exp.fulfill()
        }
    }
    
    /// State update handler for channel
    ///
    /// - Parameters:
    ///   - state: state changes from `FusionState`
    ///   - channel: the current `FusionChannel`
    private func onStateUpdate(state: FusionState, channel: FusionChannel, test: TestCase) {
        if case .ready = state {
            if test == .string { channel.send(message: buffer) }
            if test == .data { channel.send(message: Data(count: Int(buffer)!)) }
            if test == .ping { channel.send(message: UInt16(buffer)!) }
        }
        if case .cancelled = state { exp.fulfill() }
        if case let .failed(error) = state { guard let error else { return }; XCTFail("failed with error: \(error)") }
    }
}
