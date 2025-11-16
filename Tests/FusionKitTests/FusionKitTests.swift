//
//  FusionKitTests.swift.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import XCTest
@testable import FusionKit

private enum TestCase {
    case string
    case data
    case ping
}

class FusionKitTests: XCTestCase, @unchecked Sendable {
    private var connection = try? FusionConnection(host: "localhost", port: 7878)
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
    
    /// Start test error description mapping
    func testErrorDescription() {
        XCTAssertEqual(FusionFramerError.parsingFailed.description, "message parsing failed")
        XCTAssertEqual(FusionFramerError.readBufferOverflow.description, "read buffer overflow")
        XCTAssertEqual(FusionFramerError.writeBufferOverflow.description, "write buffer overflow")
        XCTAssertEqual(FusionFramerError.unexpectedOpcode.description, "unexpected opcode")
        
        do { _ = try FusionConnection(host: "", port: 7878) } catch {
            guard let error = error as? FusionFramerError else { return }
            XCTAssert(error.description == FusionConnectionError.missingHost.description)
        }
        do { _ = try FusionConnection(host: "de0.weist.org", port: 0) } catch {
            guard let error = error as? FusionFramerError else { return }
            XCTAssert(error.description == FusionConnectionError.missingPort.description)
        }
        
        exp.fulfill()
        wait(for: [exp], timeout: timeout)
    }
}

// MARK: - Private API Extension -

private extension FusionKitTests {
    /// Create a connection and start
    /// - Parameter test: test case
    private func start(test: TestCase, cancel: Bool = false) {
        guard let connection else { return }
        stateUpdateHandler(connection: connection, test: test)
        connection.receive { [weak self] message, bytes in
            guard let self else { return }
            if cancel { connection.cancel() }
            if let message { assertion(message: message) }
        }
        connection.start()
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
        guard let connection else { return }
        if case let message as UInt16 = message {
            XCTAssertEqual(message, UInt16(buffer))
            connection.cancel(); exp.fulfill()
        }
        if case let message as Data = message {
            XCTAssertEqual(message.count, Int(buffer))
            connection.cancel(); exp.fulfill()
        }
        if case let message as String = message {
            XCTAssertEqual(message, buffer)
            connection.cancel(); exp.fulfill()
        }
    }
    
    /// State update handler for connection
    /// - Parameter connection: instance of 'NetworkConnection'
    private func stateUpdateHandler(connection: FusionConnection, test: TestCase) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                if test == .string { connection.send(message: buffer) }
                if test == .data { connection.send(message: Data(count: Int(buffer)!)) }
                if test == .ping { connection.send(message: UInt16(buffer)!) }
            }
            if case .cancelled = state { exp.fulfill() }
            if case let .failed(error) = state { guard let error else { return }; XCTFail("failed with error: \(error)") }
        }
    }
}
