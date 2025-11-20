//
//  FusionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - RxTx Bytes -

/// The `FusionReport` for inbound and outbound bytes
public struct FusionReport: Sendable {
    public internal(set) var inbound: Int?
    public internal(set) var outbound: Int?
}

// MARK: - State Types -

/// The `FusionState` state handler
@frozen
public enum FusionState: Sendable {
    case ready
    case cancelled
    case failed(Error?)
}

/// The `FusionResult` internal message transmitter
internal enum FusionResult: Sendable {
    case message(FusionMessage)
    case bytes(FusionReport)
}
