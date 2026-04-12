//
//  Migrator.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

public struct Migrator {
  private let appStateResetter: any AppStateResetter
  private let versionStore: any VersionStore
  private let minimumSupportedVersion: Int
  private let logger: (any Logger)?

  private var migrations: [any Migration] = []

  public init(
    appStateResetter: any AppStateResetter,
    versionStore: any VersionStore,
    minimumSupportedVersion: Int = -1,
    logger: (any Logger)? = nil,
  ) {
    self.appStateResetter = appStateResetter
    self.versionStore = versionStore
    self.minimumSupportedVersion = minimumSupportedVersion
    self.logger = logger
  }

  public mutating func register(migration: any Migration) {
    let lastVersion = migrations.last?.version ?? minimumSupportedVersion
    guard migration.version == lastVersion + 1
    else { fatalError("Incorrect migrations order") }
    self.migrations.append(migration)
  }

  public func migrateIfNeeded() throws {
    let currentVersion = versionStore.current()
    let targetVersion = migrations.last?.version
    logger?.migrateIfNeeded(
      currentVersion: currentVersion,
      targetVersion: targetVersion,
      minimumSupportedVersion: minimumSupportedVersion
    )
    guard let targetVersion else { return }
    guard let currentVersion else {
      try update(version: targetVersion)
      return
    }
    guard currentVersion >= minimumSupportedVersion
    else {
      appStateResetter.resetEverything()
      try update(version: targetVersion)
      return
    }
    for migration in migrations where currentVersion < migration.version {
      logger?.migrate(from: versionStore.current(), to: migration.version)
      try migration.migrate()
      try update(version: migration.version)
    }
  }
}

extension Migrator {
  public mutating func register(_ migrations: [any Migration]) {
    migrations.forEach {
      self.register(migration: $0)
    }
  }
}

private extension Migrator {
  private func update(version: Int) throws {
    try versionStore.update(version)
    logger?.didUpdate(version: version)
  }
}
