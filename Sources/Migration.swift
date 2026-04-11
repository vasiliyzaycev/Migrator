//
//  Migration.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

public protocol Migration {
  var version: Int { get }

  func migrate() throws
}
