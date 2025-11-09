//
//  Extensions.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - String Extensions -

internal extension String {
    /// identifier name
    static var identifier: Self {
        return "FusionKit.\(UUID().uuidString)"
    }
}

// MARK: - UInt32 Extensions -

internal extension UInt32 {
    /// Convert integer to data with bigEndian
    var bigEndianBytes: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
}

// MARK: - Int Extensions -

internal extension Int {
    /// Minimum size of received bytes
    static var minimum: Self { 0x1 }
    
    /// Maximum size of received bytes
    static var maximum: Self { 0x8000 }
}

// MARK: - Data Extensions -

internal extension Data {
    /// Slice data into chunks
    var chunks: [Data] {
        let size = Int.maximum
        return stride(from: .zero, to: count, by: size).map { subdata(in: $0..<(count - $0 > size ? $0 + size : count)) }
    }
    
    /// Extract integers from data as big endian
    var bigEndian: UInt32 {
        guard !self.isEmpty else { return .zero }
        return UInt32(bigEndian: withUnsafeBytes { $0.load(as: UInt32.self) })
    }
    
    /// Extract the message frame size from the data,
    /// if not possible it returns nil
    ///
    /// - Returns: the size as `UInt32`
    var length: UInt32 {
        guard self.count >= FKConstants.control.rawValue else { return .zero }
        let size = self.subdata(in: FKConstants.opcode.rawValue..<FKConstants.control.rawValue)
        return Data(size).bigEndian
    }
    
    /// Extract the message and remove the overhead,
    /// if not possible it returns nil
    ///
    /// - Returns: the extracted message as `Data`
    func payload() -> Data? {
        guard self.count >= FKConstants.control.rawValue else { return nil }
        guard self.length > FKConstants.control.rawValue else { return Data() }
        return Data(self.subdata(in: FKConstants.control.rawValue..<Int(self.length)))
    }
}
