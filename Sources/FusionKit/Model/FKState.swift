//
//  FKState.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 09.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

/// The `FKBytes` for inbound and outbound bytes
public struct FKBytes: Sendable {
    public internal(set) var inbound: Int?
    public internal(set) var outbound: Int?
    
    internal init(inbound: Int? = nil, outbound: Int? = nil) {
        self.inbound = inbound
        self.outbound = outbound
    }
}

// MARK: - State Types -

/// The `FKEndpoint` where to connect
public struct FKEndpoint: Sendable {
    public let host: NWEndpoint.Host
    public let port: NWEndpoint.Port
    
    public init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.host = host
        self.port = port
    }
}
