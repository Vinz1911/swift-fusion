//
//  FusionState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

// MARK: - Typealias -

typealias FusionStream = AsyncThrowingStream<FusionResult, Error>

// MARK: - Fusion Result -

public struct FusionResult: FusionResultProtocol, Sendable {
    public private(set) var message: FusionMessage?
    public private(set) var report: FusionReport
    
    /// The `FusionResult`
    /// - Parameters:
    ///   - message: the latest `FusionMessage`
    ///   - report: the latest `FusionReport`
    init(message: FusionMessage? = nil, report: FusionReport = .init()) {
        self.message = message
        self.report = report
    }
}

// MARK: - Fusion Report -

public struct FusionReport: FusionReportProtocol, Sendable {
    public private(set) var inbound: Int?
    public private(set) var outbound: Int?
    
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
