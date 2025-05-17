//
//  TranslatioinUtils.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-16.
//


func retrieveTranslation(from translations: [String: String], lang: String) -> String {
    return translations[lang] ?? ""
}
