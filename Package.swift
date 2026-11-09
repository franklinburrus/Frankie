// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Frankie",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "FrankieCore", targets: ["FrankieCore"]),
        .executable(name: "frankie-cli", targets: ["FrankieCLI"])
    ],
    targets: [
        .target(
            name: "FrankieCore",
            path: "Frankie/Core"
        ),
        .executableTarget(
            name: "FrankieCLI",
            dependencies: ["FrankieCore"],
            path: "Tools/FrankieCLI"
        ),
        .testTarget(
            name: "FrankieCoreTests",
            dependencies: ["FrankieCore"],
            path: "Tests/FrankieCoreTests",
            resources: [
                .copy("../../Fixtures/synthetic")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
