//
//  FusionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Result Type -

/// The `FusionResult` internal message transmitter
@frozen
public enum FusionResult: Sendable {
    case ready
    case failure(Error)
    case message(FusionMessage)
    case report(FusionReport)
}

// MARK: - Byte Report -

/// The `FusionReport` for inbound and outbound bytes
public struct FusionReport: Sendable {
    public private(set) var inbound: Int?
    public private(set) var outbound: Int?
    
    /// Create a `FusionReport`
    ///
    /// - Parameters:
    ///   - inbound: incoming byte snapshot
    ///   - outbound: outgoing byte snapshot
    internal init(inbound: Int? = nil, outbound: Int? = nil) {
        self.inbound = inbound
        self.outbound = outbound
    }
}
