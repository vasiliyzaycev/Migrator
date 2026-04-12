//
//  MigratorTests.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

import Migrator
import Testing

@Suite struct MigratorTests {
  @Test func `no migrations, does nothing`() throws {
    let store = InMemoryVersionStore()
    let resetter = SpyAppStateResetter()
    let migrator = Migrator(appStateResetter: resetter, versionStore: store)
    try migrator.migrateIfNeeded()
    #expect(store.version == nil)
    #expect(resetter.resetCount == 0)
  }

  @Test func `fresh install, sets latest version without running migrations`() throws {
    let store = InMemoryVersionStore()
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(appStateResetter: resetter, versionStore: store)
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 0) { migratedVersions.append(0) },
      RecordingMigration(version: 1) { migratedVersions.append(1) },
      RecordingMigration(version: 2) { migratedVersions.append(2) },
    ])
    try migrator.migrateIfNeeded()
    #expect(migratedVersions.isEmpty)
    #expect(store.version == 2)
    #expect(resetter.resetCount == 0)
  }

  @Test func `already up to date, runs no migrations`() throws {
    let store = InMemoryVersionStore()
    store.version = 2
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(appStateResetter: resetter, versionStore: store)
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 0) { migratedVersions.append(0) },
      RecordingMigration(version: 1) { migratedVersions.append(1) },
      RecordingMigration(version: 2) { migratedVersions.append(2) },
    ])
    try migrator.migrateIfNeeded()
    #expect(migratedVersions.isEmpty)
    #expect(store.version == 2)
  }

  @Test func `partial migration, runs only pending migrations`() throws {
    let store = InMemoryVersionStore()
    store.version = 1
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(appStateResetter: resetter, versionStore: store)
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 0) { migratedVersions.append(0) },
      RecordingMigration(version: 1) { migratedVersions.append(1) },
      RecordingMigration(version: 2) { migratedVersions.append(2) },
      RecordingMigration(version: 3) { migratedVersions.append(3) },
    ])
    try migrator.migrateIfNeeded()
    #expect(migratedVersions == [2, 3])
    #expect(store.version == 3)
  }

  @Test func `each migration, updates version before the next one starts`() throws {
    let store = InMemoryVersionStore()
    store.version = 0
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(appStateResetter: resetter, versionStore: store)
    var versionsObservedDuringMigration: [Int] = []
    migrator.register([
      RecordingMigration(version: 0),
      RecordingMigration(version: 1) {
        versionsObservedDuringMigration.append(try #require(store.version))
      },
      RecordingMigration(version: 2) {
        versionsObservedDuringMigration.append(try #require(store.version))
      },
    ])
    try migrator.migrateIfNeeded()
    #expect(versionsObservedDuringMigration == [0, 1])
    #expect(store.version == 2)
  }

  @Test func `failing migration, propagates error and halts progress`() throws {
    struct MigrationError: Error, Equatable {}

    let store = InMemoryVersionStore()
    store.version = 0
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(appStateResetter: resetter, versionStore: store)
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 0) { migratedVersions.append(0) },
      RecordingMigration(version: 1) { throw MigrationError() },
      RecordingMigration(version: 2) { migratedVersions.append(2) },
    ])
    #expect(throws: MigrationError.self) {
      try migrator.migrateIfNeeded()
    }
    #expect(migratedVersions.isEmpty) // migration 2 never ran
    #expect(store.version == 0)       // version not advanced past the failure
  }

  @Test func `version minus one, runs all migrations`() throws {
    let store = InMemoryVersionStore()
    store.version = -1
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(appStateResetter: resetter, versionStore: store)
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 0) { migratedVersions.append(0) },
      RecordingMigration(version: 1) { migratedVersions.append(1) },
      RecordingMigration(version: 2) { migratedVersions.append(2) },
    ])
    try migrator.migrateIfNeeded()
    #expect(migratedVersions == [0, 1, 2])
    #expect(resetter.resetCount == 0)
    #expect(store.version == 2)
  }

  @Test func `version below minimum supported, resets state and sets latest version`() throws {
    let store = InMemoryVersionStore()
    store.version = 1
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(
      appStateResetter: resetter,
      versionStore: store,
      minimumSupportedVersion: 3
    )
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 4) { migratedVersions.append(4) },
      RecordingMigration(version: 5) { migratedVersions.append(5) },
    ])
    try migrator.migrateIfNeeded()
    #expect(migratedVersions.isEmpty)
    #expect(resetter.resetCount == 1)
    #expect(store.version == 5)
  }

  @Test func `version at minimum supported, does not reset`() throws {
    let store = InMemoryVersionStore()
    store.version = 3
    let resetter = SpyAppStateResetter()
    var migrator = Migrator(
      appStateResetter: resetter,
      versionStore: store,
      minimumSupportedVersion: 3
    )
    var migratedVersions: [Int] = []
    migrator.register([
      RecordingMigration(version: 4) { migratedVersions.append(4) },
      RecordingMigration(version: 5) { migratedVersions.append(5) },
    ])
    try migrator.migrateIfNeeded()
    #expect(migratedVersions == [4, 5])
    #expect(resetter.resetCount == 0)
    #expect(store.version == 5)
  }
}
