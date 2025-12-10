//
//  FusionResultProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 10.12.25.
//

import Foundation

// MARK: - Fusion Result Protocol -

public protocol FusionResultProtocol: Sendable {
    /// The latest `FusionMessage`
    var message: FusionMessage? { get }
    
    /// The received bytes snapshot as `Int`
    var inbound: Int? { get }
    
    /// The sent bytes snapshot as `Int`
    var outbound: Int? { get }
}
