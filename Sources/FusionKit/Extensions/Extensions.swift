//
//  Extensions.swift
//  FusionKit
//
//  Created by Vinzenz Weist on 07.06.21.
//  Copyright © 2021 Vinzenz Weist. All rights reserved.
//

import Foundation
import Network

// MARK: - UInt32 -

extension UInt32 {
    /// Convert integer to data with bigEndian
    var endian: Data { withUnsafeBytes(of: self.bigEndian) { Data($0) } }
    
    /// The fusion frame payload range
    var payload: Range<Int>? {
        guard self >= FusionStatic.header.rawValue else { return nil }
        return FusionStatic.header.rawValue..<Int(self)
    }
}

// MARK: - Range -

extension Range {
    /// The fusion frame length range
    static var length: Range<Int> {
        FusionStatic.opcode.rawValue..<FusionStatic.header.rawValue
    }
}

// MARK: - Duration -

extension Duration {
    /// Interval time
    static var interval: Self { .milliseconds(50) }
    
    /// Timeout deadline
    static var timeout: Self { .seconds(4.0) }
}

// MARK: - Network -

extension NWParameters {
    /// Creates a parameters object that is configured for TLS and TCP.
    ///
    /// - Parameters:
    ///   - tls: TLS options or nil for no TLS
    ///   - tcp: TCP options. Defaults to NWProtocolTCP.Options() with no options overridden.
    ///   - serviceClass: ServiceClass. Default is best effort.
    convenience init(tls: NWProtocolTLS.Options?, tcp: NWProtocolTCP.Options, serviceClass: NWParameters.ServiceClass = .bestEffort) {
        self.init(tls: tls, tcp: tcp)
        self.serviceClass = serviceClass
    }
}

extension NetworkConnection {
    /// Validate connection establishment
    ///
    /// Checks if connection was established otherwise throws error
    func timeout(after timeout: Duration = .timeout) async throws -> Void {
        let clock = ContinuousClock(), deadline = clock.now + timeout
        while !Task.isCancelled {
            switch self.state { case .ready: return case .failed(let error), .waiting(let error): throw error default: break }
            guard clock.now < deadline else { throw FusionConnectionError.connectionTimeout }; try await clock.sleep(for: .interval)
        }
    }
}

// MARK: - Data -

extension Data {
    /// Slice data into chunks
    ///
    /// - Parameter leverage: the size of each chunk as `Int`
    func chunks(of leverage: FusionLeverage) -> [Data] {
        if leverage == .extreme { return [self] }
        let size: Int = Swift.min(leverage.rawValue, Int(UInt16.max / 2))
        return stride(from: .zero, to: count, by: size).map { subdata(in: $0..<(count - $0 > size ? $0 + size : count)) }
    }
    
    /// Extract `UInt32` from data as big endian
    var endian: UInt32? {
        guard count >= MemoryLayout<UInt32>.size else { return nil }
        return UInt32(bigEndian: withUnsafeBytes { $0.load(as: UInt32.self) })
    }
}

// MARK: - Fusion Framer Data -

extension Data {
    /// Extract `UInt32` from payload
    ///
    /// - Returns: the extracted length as `UInt32
    func length() -> UInt32? {
        guard self.count >= FusionStatic.header.rawValue else { return nil }
        return Data(self.subdata(in: .length)).endian
    }
    
    /// Decode a `FusionMessage` as `FusionFrame`
    ///
    /// - Parameters:
    ///   - opcode: the `FusionOpcode`
    ///   - length: the length of the payload
    /// - Returns: the `FusionMessage`
    func decode(with opcode: UInt8, from length: UInt32) -> FusionFrame? {
        guard let range = length.payload else { return nil }
        return FusionOpcode(rawValue: opcode)?.type.decode(from: Data(self.subdata(in: range)))
    }
}
