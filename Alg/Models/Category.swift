//
//  Category.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-15.
//
import Foundation

struct Category: Identifiable, Decodable {
    let id: UUID
    let translations: [String: String]
    let entries: [WordEntry]
    
    static let allCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}
