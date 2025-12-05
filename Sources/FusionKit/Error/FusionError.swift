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
    case channelTimeout
    case alreadyEstablished
    
    public var description: String {
        switch self {
        case .alreadyEstablished: return "the channel is already established"
        case .channelTimeout: return "channel run into timeout, failed to establish channel" }
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
