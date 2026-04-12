//
//  TestDoubles.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

import Migrator

final class InMemoryVersionStore: VersionStore {
  var version: Int?

  func current() -> Int? {
    version
  }

  func update(_ version: Int) throws {
    self.version = version
  }
}

final class SpyAppStateResetter: AppStateResetter {
  var resetCount = 0

  func resetEverything() {
    resetCount += 1
  }
}

struct RecordingMigration: Migration {
  let version: Int

  private let body: () throws -> Void

  init(version: Int, body: @escaping () throws -> Void = {}) {
    self.version = version
    self.body = body
  }

  func migrate() throws {
    try body()
  }
}
