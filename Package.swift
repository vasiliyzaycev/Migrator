// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "Migrator",
  platforms: [.iOS(.v18)],
  products: [
    .library(
      name: "Migrator",
      targets: ["Migrator"]
    )
  ],
  targets: [
    .target(
      name: "Migrator",
      path: "Sources"
    ),
    .testTarget(
      name: "MigratorTests",
      dependencies: ["Migrator"],
      path: "Tests"
    )
  ]
)

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.enableUpcomingFeature("ExistentialAny"))
  settings.append(.enableUpcomingFeature("MemberImportVisibility"))
  target.swiftSettings = settings
}
