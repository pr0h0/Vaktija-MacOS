// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Vaktija",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "VaktijaCore", targets: ["VaktijaCore"])
    ],
    targets: [
        .target(name: "VaktijaCore", exclude: ["Info.plist"]),
        .testTarget(name: "VaktijaCoreTests", dependencies: ["VaktijaCore"])
    ]
)
