//
//  VersionStore.swift
//  Migrator
//
//  Created by Vasiliy Zaycev on 11.04.2026.
//

public protocol VersionStore {
  func current() -> Int?
  func update(_: Int) throws
}
