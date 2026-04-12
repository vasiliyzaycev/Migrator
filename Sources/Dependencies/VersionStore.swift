//
//  VersionStore.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

/// Persists the current migration version across app launches.
public protocol VersionStore {
  /// Returns the last successfully applied migration version,
  /// `nil` if no migrations have been applied yet (e.g. on a fresh install),
  /// or `-1` if the app was installed before the migrator was introduced — in which case all known migrations will be applied.
  func current() -> Int?
  func update(_: Int) throws
}
