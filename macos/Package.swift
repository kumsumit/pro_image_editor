// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pro_image_editor",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "pro_image_editor", targets: ["pro_image_editor"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "pro_image_editor",
            dependencies: [],
            path: "Sources/pro_image_editor",
            resources: []
        )
    ]
)
