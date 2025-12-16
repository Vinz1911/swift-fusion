//
//  FusionState.swift
//  Fusion
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Typealias -

typealias FusionStream = AsyncThrowingStream<FusionResult, Error>

// MARK: - Fusion Result -

@frozen
public struct FusionResult: FusionResultProtocol, Sendable {
    public let message: FusionMessage?
    public let report: FusionReport?
    
    /// The `FusionResult`
    /// - Parameters:
    ///   - message: the latest `FusionMessage`
    ///   - report: the latest `FusionReport`
    init(message: FusionMessage? = nil, report: FusionReport? = nil) {
        self.message = message
        self.report = report
    }
}

// MARK: - Fusion Report -

@frozen
public struct FusionReport: FusionReportProtocol, Sendable {
    public let inbound: Int?
    public let outbound: Int?
    
    /// The `FusionReport`
    ///
    /// - Parameters:
    ///   - inbound: incoming bytes snapshot as `Int`
    ///   - outbound: outgoing bytes snapshot as `Int`
    init(inbound: Int? = nil, outbound: Int? = nil) {
        self.inbound = inbound
        self.outbound = outbound
    }
}
