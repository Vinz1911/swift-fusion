//
//  FusionResultProtocol.swift
//  Fusion
//
//  Created by Vinzenz Weist on 10.12.25.
//

import Foundation

// MARK: - Fusion Result Protocol -

public protocol FusionResultProtocol: Sendable {
    /// The latest `FusionMessage`
    var message: FusionMessage? { get }
    
    /// The latest `FusionReport`
    var report: FusionReport? { get }
}

// MARK: - Fusion Report -

public protocol FusionReportProtocol: Sendable {
    /// The incoming bytes snapshot as `Int`
    var inbound: Int? { get }
    
    /// The outgoing bytes snapshot as `Int`
    var outbound: Int? { get }
}
