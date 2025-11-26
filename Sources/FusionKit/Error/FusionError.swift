//
//  FusionError.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Fusion Channel Error -

/// The `FusionChannelError` specific errors
@frozen
public enum FusionChannelError: Error, Sendable {
    case invalidHostName
    case invalidPortNumber
    case channelTimeout
    case unsupportedProtocol
    
    public var description: String {
        switch self {
        case .invalidHostName: return "host name is invalid, failed to create instance"
        case .invalidPortNumber: return "port number is invalid, failed to create instance"
        case .channelTimeout: return "channel run into timeout, failed to establish channel"
        case .unsupportedProtocol: return "protocol is unsupported, use .tcp or .tls instead" }
    }
}

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: Error, Sendable {
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
