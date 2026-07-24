// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DoNotSleep",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DoNotSleep", targets: ["DoNotSleep"])
    ],
    targets: [
        .executableTarget(
            name: "DoNotSleep",
            path: "Sources/DoNotSleep"
        )
    ]
)
