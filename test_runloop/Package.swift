// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "test_runloop",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "test_runloop", targets: ["test_runloop"]),
    ],
    targets: [
        .executableTarget(
            name: "test_runloop",
            path: "Sources"
        ),
    ]
)
