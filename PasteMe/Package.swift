// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PasteMe",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "PasteMe", targets: ["PasteMe"])
    ],
    targets: [
        .executableTarget(
            name: "PasteMe",
            path: "PasteMe",
            exclude: [
                "Info.plist",
                "PasteMe.entitlements"
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
