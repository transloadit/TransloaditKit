// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TransloaditKit",
    platforms: [.iOS(.v10), .macOS(.v10_10)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TransloaditKit",
            targets: ["TransloaditKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "TUSKit", url: "https://github.com/tus/TUSKit", from: "3.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TransloaditKit",
            dependencies: ["TUSKit"]),
        .testTarget(
            name: "TransloaditKitTests",
            dependencies: ["TransloaditKit"]),
    ]
)
