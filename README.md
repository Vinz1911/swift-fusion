# FusionKit
The `FusionChannel` is a custom network connector that implements the **Fusion Framing Protocol (FFP)**
It is built on top of the standard `Network` framework library. This fast and lightweight custom framing protocol 
enables high-speed data transmission and provides fine-grained control over network flow.

# Overview
| Swift Version                                                                                                | License                                                                                                                                              | Coverage                                                                                                                                              |
|--------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| [![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg?logo=swift&style=flat)](https://swift.org)   | [![License](https://img.shields.io/badge/license-GPLv3-blue.svg?longCache=true&style=flat)](https://github.com/Vinz1911/FusionKit/blob/main/LICENSE) | [![codecov](https://codecov.io/github/Vinz1911/FusionKit/branch/main/graph/badge.svg?token=EE3S0BOINS)](https://codecov.io/github/Vinz1911/FusionKit) |
| [![Swift 6.2](https://img.shields.io/badge/SPM-Support-orange.svg?logo=swift&style=flat)](https://swift.org) |                                                                                                                                                      |                                                                                                                                                       |

## Installation:
### Swift Packages

> [!IMPORTANT]  
> With the beginning of version 20.0.0 the framework uses an entire new private and public interface.
> The Framework was migrated to use the new structured concurrency based API for safe and easy handling.
> Below version 20.0.0 can be used for 'old' API interface but will not be actively maintained anymore.

```swift
// ...
dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/Vinz1911/FusionKit.git", exact: "20.0.0"),
],
// ...
```

## Import:
```swift
// Import the Framework
import FusionKit

// Create a new channel
let channel = try FusionChannel(host: "example.com", port: 7878)

// Support for NWProtocolTCP.Options, tls example:
let channel = try FusionChannel(host: "example.com", port: 7878, parameters: .init(tcp: .init()))

// ...
```

## Send Messages:
```swift
// Import the Framework
import FusionKit

// Create a new channel
let channel = try FusionChannel(host: "example.com", port: 7878)

// The framework accepts different kind of messages
// `String` for text based messages
// `Data` for raw byte messages
// `UInt16` for ping - pong messages (generates a data frame based on input value)

// Send String
try await connection.send(message: "Hello World!")

// Send Data
try await connection.send(message: Data(count: 100))

// Send UInt16
try await connection.send(message: UInt16.max)
```

## Parse Message:
```swift
// Import the Framework
import FusionKit

// Create a new channel
let channel = try FusionChannel(host: "example.com", port: 7878)

// Send message
try await connection.send(message: "Hello World! 👻")

// Receive message and get report
for try await result in channel.receive() {
    if case .message(let message) = result {
        if let message = message as? String { print(message) }
    }
    if case .report(let report) = result {
        if let inbound = report.inbound { print("Incoming bytes: \(inbound)") }
        if let outbound = report.outbound { print("Outgoing bytes: \(outbound)") }
    }
}
```

## Author:
👨🏼‍💻 [Vinzenz Weist](https://github.com/Vinz1911)
