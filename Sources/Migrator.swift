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

  private var migrations: [any Migration] = []

  public init(
    appStateResetter: any AppStateResetter,
    versionStore: any VersionStore,
    minimumSupportedVersion: Int = -1,
  ) {
    self.appStateResetter = appStateResetter
    self.versionStore = versionStore
    self.minimumSupportedVersion = minimumSupportedVersion
  }

  public mutating func register(migration: any Migration) {
    let lastVersion = migrations.last?.version ?? minimumSupportedVersion
    guard migration.version == lastVersion + 1
    else { fatalError("Incorrect migrations order") }
    self.migrations.append(migration)
  }

  public func migrateIfNeeded() throws {
    guard let targetVersion = migrations.last?.version else { return }
    guard let currentVersion = versionStore.current()
    else {
      try versionStore.update(targetVersion)
      return
    }
    guard currentVersion >= minimumSupportedVersion
    else {
      appStateResetter.resetEverything()
      try versionStore.update(targetVersion)
      return
    }
    for migration in migrations where currentVersion < migration.version {
      try migration.migrate()
      try versionStore.update(migration.version)
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
