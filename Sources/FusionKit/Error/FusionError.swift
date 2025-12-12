//
//  FusionError.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Fusion Connection Error -

/// The `FusionConnectionError` specific errors
@frozen
public enum FusionConnectionError: Error, Sendable {
    case connectionTimeout
    case alreadyEstablished
    
    public var description: String {
        switch self {
        case .alreadyEstablished: "the connection is already established and cannot be established again"
        case .connectionTimeout: "connection run into timeout, failed to establish connection" }
    }
}

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: Error, Sendable {
    case inputBufferOverflow
    case outputBufferOverflow
    case loadOpcodeFailed
    case decodeMessageFailed
    
    public var description: String {
        switch self {
        case .inputBufferOverflow: "input buffer overflow occured while reading from the underlying socket"
        case .outputBufferOverflow: "output buffer overflow occured while preparing message frame"
        case .loadOpcodeFailed: "unable to load opcode, discard this frame (this should never happen!)"
        case .decodeMessageFailed: "unable to decode message, discard this frame" }
    }
}
