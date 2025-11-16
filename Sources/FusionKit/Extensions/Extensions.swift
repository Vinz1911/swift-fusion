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
    /// Minimum size of received bytes
    static var minimum: Self { 0x1 }
    
    /// Maximum size of received bytes
    static var maximum: Self { 0x8000 }
}

internal extension UInt32 {
    /// Convert integer to data with bigEndian
    var endian: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
}

// MARK: - Data -

internal extension Data {
    /// Slice data into chunks
    var chunks: [Data] {
        let size = Int.maximum
        return stride(from: .zero, to: count, by: size).map { subdata(in: $0..<(count - $0 > size ? $0 + size : count)) }
    }
    
    /// Extract `UInt32` from data as big endian
    var endian: UInt32? {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { $0.load(as: UInt32.self) })
    }
}

internal extension DispatchData {
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
