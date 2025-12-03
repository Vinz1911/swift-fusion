//
//  FusionFramerProtocol.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation

internal protocol FusionFramerProtocol: Sendable {
    /// Creates an instance of `FusionFramer`.
    ///
    /// The `FusionFramer` implements the **Fusion Framing Protocol (FFP)** —
    /// a fast and lightweight message framing protocol that supports both
    /// `ByteBuffer`- and `String`-based messages.
    ///
    /// It also provides support for `UInt16`, allowing the creation of data frames
    /// with a defined size, which can be used for round-trip time (RTT) measurements.
    ///
    /// The protocol adds only `0x5` bytes of overhead per message and relies on TCP
    /// flow control, resulting in a highly efficient and lightweight framing protocol.
    ///
    ///     Protocol Structure
    ///    +--------+---------+-------------+
    ///    | 0      | 1 2 3 4 | 5 6 7 8 9 N |
    ///    +--------+---------+-------------+
    ///    | Opcode | Length  |   Payload   |
    ///    | [0x1]  | [0x4]   |   [...]     |
    ///    |        |         |             |
    ///    +--------+---------+- - - - - - -+
    ///
    /// This protocol is based on a standardized Type-Length-Value (TLV) design scheme.
    
    /// Clear the message buffer
    ///
    /// Current message buffer will be cleared
    func reset() async -> Void
    
    /// Create a `FusionMessage` conform frame
    ///
    /// - Parameter message: generic type which conforms to `FusionMessage`
    /// - Returns: the message frame as `Data`
    nonisolated func create<T: FusionMessage>(message: T) throws -> Data
    
    /// Parse a `FusionMessage` conform frame
    ///
    /// - Parameter data: the `Data` slice of the `FusionMessage`
    /// - Returns: a collection of `FusionMessage`s and `Error`
    func parse(data: Data) async throws -> [FusionMessage]
}
