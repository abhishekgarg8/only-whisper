// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OnlyWhisper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "OnlyWhisper",
            targets: ["TypewriterEntry"]
        )
    ],
    targets: [
        // Library: all app logic — services, models, views, coordinator.
        // Imported by both the executable and the test target.
        .target(
            name: "TypewriterApp",
            path: "TypewriterApp",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        ),

        // Executable: only the @main App struct. Depends on the library.
        .executableTarget(
            name: "TypewriterEntry",
            dependencies: ["TypewriterApp"],
            path: "TypewriterEntry"
        ),

        // Tests: import the library with @testable to access internal types.
        .testTarget(
            name: "TypewriterAppTests",
            dependencies: ["TypewriterApp"],
            path: "Tests/TypewriterAppTests"
        )
    ]
)
