//
//  Extensions.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - Int -

internal extension Int {
    /// Minimum size for bytes control
    static var minimum: Self { 0x1 }
    
    /// Maximum size for bytes control
    static var maximum: Self { 0x8000 }
}

internal extension UInt32 {
    /// Convert integer to data with bigEndian
    var endian: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
}

// MARK: - Duration -

internal extension Duration {
    /// Interval time
    static var interval: Self { .milliseconds(50) }
    
    /// Timeout deadline
    static var timeout: Self { .seconds(4.0) }
}

// MARK: - Network -

extension NetworkConnection {
    /// Validate channel establishment
    ///
    /// Checks if channel was established otherwise throws error
    func timeout() async throws -> Void {
        let clock = ContinuousClock(), deadline = clock.now + .timeout
        while !Task.isCancelled {
            switch self.state { case .ready: return case .failed(let error), .waiting(let error): throw error default: break }
            guard clock.now < deadline else { throw FusionChannelError.channelTimeout }; try await clock.sleep(for: .interval)
        }
    }
}

// MARK: - Data -

internal extension Data {
    /// Slice data into chunks
    ///
    /// - Parameter leverage: the size of each chunk as `Int`
    func chunks(of leverage: FusionLeverage) -> [Data] {
        let size: Int = Swift.min(leverage.rawValue, .maximum)
        return stride(from: .zero, to: count, by: size).map { subdata(in: $0..<(count - $0 > size ? $0 + size : count)) }
    }
    
    /// Extract `UInt32` from data as big endian
    var endian: UInt32? {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { $0.load(as: UInt32.self) })
    }
    
    /// Extract `UInt32` from `DispatchData`
    ///
    /// - Returns: the extracted length as `UInt32
    func extractLength() -> UInt32? {
        let length = Data(self.subdata(in: FusionConstants.opcode.rawValue..<FusionConstants.header.rawValue))
        return length.endian
    }
    
    /// Extract `Data` from `DispatchData`
    ///
    /// - Parameter length: the amount of bytes to extract
    /// - Returns: the extracted bytes as `Data`
    func extractPayload(length: UInt32) -> Data? {
        return Data(self.subdata(in: FusionConstants.header.rawValue..<Int(length)))
    }
}
