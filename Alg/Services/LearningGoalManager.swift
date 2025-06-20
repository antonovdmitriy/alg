//
//  LearningGoalManager.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-25.
//


import Foundation
import SwiftUI

class LearningGoalManager: ObservableObject {
    static let shared = LearningGoalManager()

    @AppStorage("dailyGoal") var dailyGoal: Int = 10
    @AppStorage("lastProgressDate") var lastDate: String = ""
    @AppStorage("wordsLearnedToday") var learnedToday: Int = 0 {
        didSet {
            objectWillChange.send()
        }
    }
    @AppStorage("goalAnimationShownDate") var goalAnimationShownDate: String = ""
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false

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
        hasSelectedDailyGoal && isGoalReached && goalAnimationShownDate != currentDateString
    }

    func markGoalAnimationShown() {
        goalAnimationShownDate = currentDateString
        AppReviewManager.requestReviewIfAppropriate()
    }

    func resetIfNewDay() {
        if currentDateString != lastDate {
            resetDailyProgress()
            lastDate = currentDateString
        }
    }
    
    func resetDailyProgress() {
        learnedToday = 0
        goalAnimationShownDate = ""
    }
}
