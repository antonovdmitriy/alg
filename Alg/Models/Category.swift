//
//  Category.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-15.
//
import Foundation

struct Category: Identifiable, Decodable {
    let id: UUID
    let name: String
    let entries: [WordEntry]
}
