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
        case .alreadyEstablished: return "the channel is already established and cannot be established again"
        case .channelTimeout: return "channel run into timeout, failed to establish channel" }
    }
}

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: Error, Sendable {
    case frameParsingFailed
    case inputBufferOverflow
    case outputBufferOverflow
    case invalidFrameOpcode
    
    public var description: String {
        switch self {
        case .frameParsingFailed: return "unable to parse frame into a usable format"
        case .inputBufferOverflow: return "input buffer overflow occured while reading from the underlying socket"
        case .outputBufferOverflow: return "output buffer overflow occured while preparing message frame"
        case .invalidFrameOpcode: return "invalid opcode, discard this frame" }
    }
}
