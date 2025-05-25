//
//  LearningGoalManager.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-25.
//


import Foundation
import SwiftUI

class LearningGoalManager {
    static let shared = LearningGoalManager()

    @AppStorage("dailyGoal") var dailyGoal: Int = 10
    @AppStorage("lastProgressDate") var lastDate: String = ""
    @AppStorage("wordsLearnedToday") var learnedToday: Int = 0
    @AppStorage("goalAnimationShownDate") var goalAnimationShownDate: String = ""

    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func incrementProgress() {
        if currentDateString != lastDate {
            learnedToday = 0
            lastDate = currentDateString
        }
        learnedToday += 1
    }

    var progressFraction: Double {
        min(Double(learnedToday) / Double(dailyGoal), 1.0)
    }

    var isGoalReached: Bool {
        learnedToday >= dailyGoal
    }

    var shouldShowGoalAnimation: Bool {
        isGoalReached && goalAnimationShownDate != currentDateString
    }

    func markGoalAnimationShown() {
        goalAnimationShownDate = currentDateString
    }

    func resetIfNewDay() {
        if currentDateString != lastDate {
            learnedToday = 0
            lastDate = currentDateString
        }
    }
}
