//
//  FusionError.swift
//  Fusion
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Fusion Connection Error -

/// The `FusionConnectionError` specific errors
@frozen
public enum FusionConnectionError: Error, CaseIterable, Sendable {
    case established
    case timeout
    
    public var description: String {
        switch self {
        case .established: "the connection is already established and cannot be established again"
        case .timeout: "connection run into timeout, failed to establish connection" }
    }
}

// MARK: - Fusion Framer Error -

/// The `FusionFramerError` specific errors
@frozen
public enum FusionFramerError: Error, CaseIterable, Sendable {
    case inbound
    case outbound
    case invalid
    case opcode
    case decode
    
    public var description: String {
        switch self {
        case .inbound: "inbound buffer overflow occured while reading from the underlying socket"
        case .outbound: "outbound buffer overflow occured while preparing message frame"
        case .invalid: "invalid length is not allowed, discard this frame"
        case .opcode: "unable to extract opcode, discard this frame (this should never happen!)"
        case .decode: "unable to decode message, discard this frame" }
    }
}
