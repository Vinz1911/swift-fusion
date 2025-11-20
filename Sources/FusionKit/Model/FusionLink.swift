//
//  FusionLink.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

public final class FusionLink: FusionLinkProtocol, @unchecked Sendable {
    public var onStateUpdate: (@Sendable (FusionState) -> Void) = { _ in }
    
    private var result: (@Sendable (FusionResult) -> Void) = { _ in }
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let framer = FusionFramer()
    private let link: NWConnection
    
    /// The `FusionLink` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**.
    /// It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol
    /// enables high-speed data transmission and provides fine-grained control over network flow.
    ///
    /// - Parameters:
    ///   - host: the host name as `String`
    ///   - port: the host port as `UInt16`
    ///   - parameters: network framework `NWParameters`
    ///   - qos: quality of service class `DispatchQoS`
    public required init(host: String, port: UInt16, parameters: NWParameters = .tcp, qos: DispatchQoS = .userInteractive) throws {
        if host.isEmpty { throw(FusionLinkError.invalidHostName) }; if port == .zero { throw(FusionLinkError.invalidPortNumber) }
        self.link = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: parameters)
        self.queue = DispatchQueue(label: UUID().uuidString, qos: qos)
    }
    
    /// Start to establish a new link
    ///
    /// Establish a new `FusionLink` to a compatible booststrap
    public func start() -> Void {
        queue.async { [weak self] in guard let self else { return }
            handler(); discontiguous(); link.start(queue: queue)
        }
        queue.asyncAfter(deadline: .now() + .timeout) { [weak self] in guard let self else { return }
            guard link.state != .ready else { return }
            teardown(); onStateUpdate(.failed(FusionLinkError.linkTimeout))
        }
    }
    
    /// Cancel an active link
    ///
    /// The current active `FusionLink` will be terminated
    public func cancel() -> Void {
        queue.async { [weak self] in guard let self else { return }
            teardown()
        }
    }
    
    /// Send a `FusionMessage` to a linked bootstraped
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    public func send<T: FusionMessage>(message: T) -> Void {
        queue.async { [weak self] in guard let self else { return }
            processing(with: message)
        }
    }
    
    /// Receive a message from a linked bootstraped
    ///
    /// - Parameter completion: contains `FusionMessage` and `FusionReport` generic message typ
    public func receive(_ completion: @Sendable @escaping (FusionMessage?, FusionReport?) -> Void) -> Void {
        result = { result in
            if case .message(let message) = result { completion(message, nil) }
            if case .bytes(let bytes) = result { completion(nil, bytes) }
        }
    }
}

// MARK: - Private API -

private extension FusionLink {
    /// Clean and cancel `FusionLink`
    ///
    /// The current active `FusionLink` will be terminated cleaned
    private func teardown() -> Void {
        link.cancel(); framer.reset()
    }
    
    /// Link handler for state updates
    ///
    /// Manages state updates for the active established link
    private func handler() -> Void {
        link.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state { onStateUpdate(.ready) }
            if case .cancelled = state { onStateUpdate(.cancelled) }
            if case .failed(let error) = state { teardown(); onStateUpdate(.failed(error)) }
        }
    }
    
    /// Process message data and send it to a linked bootstrap
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    private func processing<T: FusionMessage>(with message: T) -> Void {
        do {
            let frame = try framer.create(message: message)
            for chunk in frame.chunks { dispatch(chunk) }
        } catch {
            onStateUpdate(.failed(error)); teardown()
        }
    }
    
    /// Process message data, received rom a linked bootstrap
    ///
    /// - Parameter data: frame data as `DispatchData`
    private func processing(from data: DispatchData) -> Void {
        do {
            let messages = try framer.parse(data: data)
            for message in messages { result(.message(message)) }
        } catch {
            onStateUpdate(.failed(error)); teardown()
        }
    }
    
    /// Dispatch tcp data from a message frame
    ///
    /// - Parameter content: the content `Data` to transmit
    private func dispatch(_ content: Data) -> Void {
        link.batch {
            link.send(content: content, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                result(.bytes(FusionReport(outbound: content.count)))
                if let error, error != NWError.posix(.ECANCELED) { onStateUpdate(.failed(error)) }
            })
        }
    }
    
    /// Receive discontiguous `TCP` data frames
    ///
    /// The `DispatchData` received from a current established `FusionLink`
    private func discontiguous() -> Void {
        link.batch {
            link.receiveDiscontiguous(minimumIncompleteLength: .minimum, maximumLength: .maximum) { [weak self] content, _, isComplete, error in
                guard let self else { return }
                if let error { if error != NWError.posix(.ECANCELED) { onStateUpdate(.failed(error)); teardown(); }; return }
                if let content { result(.bytes(.init(inbound: content.count))); processing(from: content) }
                if isComplete { teardown() } else { discontiguous() }
            }
        }
    }
}
