//
//  FusionError.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Fusion Error -

public protocol FusionError: Error, Sendable { }

// MARK: - Fusion Channel Error -

/// The `FusionChannelError` specific errors
@frozen
public enum FusionChannelError: FusionError, Error, Sendable {
    case invalidEndpoint
    case channelTimeout
    
    public var description: String {
        switch self {
        case .invalidEndpoint: return "the host name or port number is invalid, failed to create instance"
        case .channelTimeout: return "channel run into timeout, failed to establish channel" }
    }
}

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: FusionError, Error, Sendable {
    case parsingFailed
    case readBufferOverflow
    case writeBufferOverflow
    case unexpectedOpcode
    
    public var description: String {
        switch self {
        case .parsingFailed: return "unable to parse message frame"
        case .readBufferOverflow: return "invalid frame size, read buffer overflow"
        case .writeBufferOverflow: return "invalid frame size, write buffer overflow"
        case .unexpectedOpcode: return "unexpected opcode, terminating" }
    }
}
