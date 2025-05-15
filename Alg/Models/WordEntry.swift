//
//  WordEntry.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-15.
//
import Foundation

struct WordEntry: Identifiable, Decodable {
    let id: UUID
    let word: String
    let translation: String
    let examples: [String]
}
