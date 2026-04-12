//
//  MigratorLogger.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

public protocol Logger {
  func migrateIfNeeded(
    currentVersion: Int?,
    targetVersion: Int?,
    minimumSupportedVersion: Int
  )

  func migrate(
    from fromVersion: Int?,
    to toVersion: Int
  )

  func didUpdate(version: Int)
}
