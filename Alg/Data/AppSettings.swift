//
//  AppSettings.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-16.
//

import Foundation

struct AppSettings {
private enum Keys {
        static let translationLanguage = "preferredTranslationLanguage"
    }

    static var translationLanguage: String {
        get {
            UserDefaults.standard.string(forKey: Keys.translationLanguage) ?? "ru"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.translationLanguage)
        }
    }
}
