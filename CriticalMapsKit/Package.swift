// swift-tools-version:5.8

import PackageDescription

let package = Package(
  name: "CriticalMapsKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    .library(name: "ApiClient", targets: ["ApiClient"]),
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "ChatFeature", targets: ["ChatFeature"]),
    .library(name: "GuideFeature", targets: ["GuideFeature"]),
    .library(name: "MapFeature", targets: ["MapFeature"]),
    .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
    .library(name: "MastodonFeedFeature", targets: ["SocialFeature"]),
    .library(name: "Styleguide", targets: ["Styleguide"])
  ],
  dependencies: [
    .package(url: "https://github.com/MarcoEidinger/SwiftFormatPlugin", from: "0.49.18"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.2.0"),
    .package(url: "https://github.com/mltbnz/composable-core-location.git", branch: "main"),
    .package(
      url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
      .upToNextMajor(from: "1.8.2")
    ),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    .package(url: "https://github.com/vtourraine/AcknowList.git", .upToNextMajor(from: "2.1.0")),
    .package(url: "https://github.com/lucaszischka/BottomSheet.git", from: "3.1.0"),
    .package(url: "https://github.com/mltbnz/MastodonKit.git", branch: "master")
  ],
  targets: [
    .target(
      name: "ApiClient",
      dependencies: [
        "Helpers",
        "SharedModels"
      ]
    ),
    .target(
      name: "AppFeature",
      dependencies: [
        "ApiClient",
        "Helpers",
        "FileClient",
        "GuideFeature",
        "Logger",
        "L10n",
        "IDProvider",
        "MapFeature",
        "NextRideFeature",
        "PathMonitorClient",
        "SettingsFeature",
        "SharedDependencies",
        "SocialFeature",
        "Styleguide",
        "UserDefaultsClient",
        "UIApplicationClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "BottomSheet", package: "BottomSheet")
      ]
    ),
    .target(
      name: "ChatFeature",
      dependencies: [
        "ApiClient",
        "Helpers",
        "IDProvider",
        "L10n",
        "Logger",
        "SharedDependencies",
        "SharedModels",
        "Styleguide",
        "SwiftUIHelpers",
        "UserDefaultsClient"
      ]
    ),
    .target(
      name: "FileClient",
      dependencies: [
        "Helpers",
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "GuideFeature",
      dependencies: [
        "Helpers",
        "L10n",
        "Logger",
        "Styleguide",
        "SwiftUIHelpers"
      ]
    ),
    .target(
      name: "Helpers",
      dependencies: [
        "Styleguide",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "IDProvider",
      dependencies: ["Helpers"]
    ),
    .target(
      name: "L10n",
      dependencies: [],
      resources: [.process("Resources")]
    ),
    .target(
      name: "Logger",
      dependencies: [
        .product(name: "Logging", package: "swift-log")
      ]
    ),
    .target(
      name: "MapFeature",
      dependencies: [
        "ApiClient",
        "Helpers",
        "L10n",
        "Logger",
        "NextRideFeature",
        "SharedDependencies",
        "SharedModels",
        "Styleguide",
        "SwiftUIHelpers",
        .product(name: "ComposableCoreLocation", package: "composable-core-location"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "NextRideFeature",
      dependencies: [
        "ApiClient",
        "Helpers",
        "L10n",
        "Logger",
        "SharedDependencies",
        "SharedModels",
        "Styleguide",
        "UserDefaultsClient",
        .product(name: "ComposableCoreLocation", package: "composable-core-location"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "PathMonitorClient"
    ),
    .target(
      name: "SettingsFeature",
      dependencies: [
        "FileClient",
        "L10n",
        "Logger",
        "Helpers",
        "SharedDependencies",
        "SharedModels",
        "Styleguide",
        "SwiftUIHelpers",
        "UIApplicationClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "AcknowList", package: "AcknowList")
      ],
      resources: [.process("Resources/")]
    ),
    .target(
      name: "SharedDependencies",
      dependencies: [
        "ApiClient",
        "FileClient",
        "IDProvider",
        "PathMonitorClient",
        "UIApplicationClient",
        "UserDefaultsClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "SharedModels",
      dependencies: [
        "Helpers",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "SocialFeature",
      dependencies: [
        "ChatFeature",
        "L10n",
        "MastodonFeedFeature",
        "UserDefaultsClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "Styleguide",
      dependencies: [
        "L10n",
        "SwiftUIHelpers"
      ],
      exclude: ["README.md"],
      resources: [.process("Resources")]
    ),
    .target(
      name: "SwiftUIHelpers",
      dependencies: []
    ),
    .target(
      name: "TestHelper",
      dependencies: [
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ]
    ),
    .target(
      name: "MastodonFeedFeature",
      dependencies: [
        "ApiClient",
        "Logger",
        "SharedDependencies",
        "SharedModels",
        "Styleguide",
        "UIApplicationClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "MastodonKit", package: "MastodonKit")
      ]
    ),
    .target(
      name: "UIApplicationClient",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "UserDefaultsClient",
      dependencies: [
        "Helpers",
        "SharedModels",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    )
  ]
)

// MARK: - Test Targets

package.targets.append(contentsOf: [
  .testTarget(
    name: "AppFeatureTests",
    dependencies: [
      "AppFeature",
      "PathMonitorClient",
      "TestHelper",
      .product(
        name: "ComposableArchitecture",
        package: "swift-composable-architecture"
      ),
      .product(name: "CustomDump", package: "swift-custom-dump")
    ],
    exclude: [
      "__Snapshots__"
    ]
  ),
  .testTarget(
    name: "ChatFeatureTests",
    dependencies: [
      "ChatFeature",
      "TestHelper",
      "SharedModels",
      "UserDefaultsClient",
      .product(name: "CustomDump", package: "swift-custom-dump")
    ],
    exclude: [
      "__Snapshots__"
    ]
  ),
  .testTarget(
    name: "HelperTests",
    dependencies: [
      "Helpers",
      "UserDefaultsClient"
    ]
  ),
  .testTarget(
    name: "IDProviderTests",
    dependencies: ["IDProvider"]
  ),
  .testTarget(
    name: "MapFeatureTests",
    dependencies: [
      "MapFeature",
      "TestHelper",
      .product(
        name: "ComposableArchitecture",
        package: "swift-composable-architecture"
      )
    ],
    exclude: [
      "__Snapshots__"
    ]
  ),
  .testTarget(
    name: "NextRideFeatureTests",
    dependencies: [
      "Helpers",
      "UserDefaultsClient",
      "NextRideFeature",
      .product(
        name: "ComposableArchitecture",
        package: "swift-composable-architecture"
      )
    ]
  ),
  .testTarget(
    name: "SocialFeatureTests",
    dependencies: [
      "SocialFeature",
      "TestHelper",
      .product(name: "CustomDump", package: "swift-custom-dump")
    ]
  ),
  .testTarget(
    name: "StyleguideTests",
    dependencies: [
      "Styleguide",
      "TestHelper",
      .product(name: "CustomDump", package: "swift-custom-dump")
    ],
    exclude: ["__Snapshots__"]
  ),
  .testTarget(
    name: "SettingsFeatureTests",
    dependencies: [
      "Helpers",
      "L10n",
      "SettingsFeature",
      "TestHelper",
      "UserDefaultsClient",
      .product(
        name: "ComposableArchitecture",
        package: "swift-composable-architecture"
      )
    ],
    exclude: ["__Snapshots__"]
  ),
  .testTarget(
    name: "MastodonFeedFeatureTests",
    dependencies: [
      "Helpers",
      "SharedDependencies",
      "MastodonFeedFeature",
      "TestHelper",
      .product(
        name: "ComposableArchitecture",
        package: "swift-composable-architecture"
      ),
      .product(name: "MastodonKit", package: "MastodonKit")
    ],
    exclude: [
      "__Snapshots__"
    ]
  )
])
