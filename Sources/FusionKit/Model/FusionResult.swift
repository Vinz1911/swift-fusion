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

// MARK: - Result Type -

public struct FusionResult: FusionResultProtocol, Sendable {
    public private(set) var message: FusionMessage?
    public private(set) var inbound: Int?
    public private(set) var outbound: Int?
    
    /// The `FusionResult`
    /// - Parameters:
    ///   - message: the latest `FusionMessage`
    ///   - inbound: the received bytes snapshot as `Int`
    ///   - outbound: the sent bytes snapshot as `Int`
    init(message: FusionMessage? = nil, inbound: Int? = nil, outbound: Int? = nil) {
        self.message = message
        self.inbound = inbound
        self.outbound = outbound
    }
}
