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
    private var link = try? FusionLink(host: "de0.weist.org", port: 7878)
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
    /// Create a link and start
    /// - Parameter test: test case
    private func start(test: TestCase, cancel: Bool = false) {
        guard let link else { return }
        onStateUpdate(link: link, test: test)
        link.receive { [weak self] message, bytes in
            guard let self else { return }
            if cancel { link.cancel() }
            if let message { assertion(message: message) }
        }
        link.start()
        wait(for: [exp], timeout: timeout)
    }
    
    /// Run framer
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
    /// - Parameter message: generic `FusionMessage`
    private func assertion(message: FusionMessage) {
        guard let link else { return }
        if case let message as UInt16 = message {
            XCTAssertEqual(message, UInt16(buffer))
            link.cancel(); exp.fulfill()
        }
        if case let message as Data = message {
            XCTAssertEqual(message.count, Int(buffer))
            link.cancel(); exp.fulfill()
        }
        if case let message as String = message {
            XCTAssertEqual(message, buffer)
            link.cancel(); exp.fulfill()
        }
    }
    
    /// State update handler for link
    /// - Parameter link: instance of 'Networklink'
    private func onStateUpdate(link: FusionLink, test: TestCase) {
        link.onStateUpdate = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                if test == .string { link.send(message: buffer) }
                if test == .data { link.send(message: Data(count: Int(buffer)!)) }
                if test == .ping { link.send(message: UInt16(buffer)!) }
            }
            if case .cancelled = state { exp.fulfill() }
            if case let .failed(error) = state { guard let error else { return }; XCTFail("failed with error: \(error)") }
        }
    }
}
