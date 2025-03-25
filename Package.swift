// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OptionalCompactDatePicker",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "OptionalCompactDatePicker",
            targets: ["OptionalCompactDatePicker"])
    ],
    targets: [
        .target(
            name: "OptionalCompactDatePicker")

    ]
)
