import StoreKit

final class AppReviewManager {
    private static let goalCountKey = "goalCompletionCount"
    private static let lastPromptKey = "lastReviewPromptDate"
    private static let minimumInterval: TimeInterval = 7 * 24 * 60 * 60
    private static let minimumGoalCount = 3

    public static func requestReviewIfAppropriate() {
        let defaults = UserDefaults.standard
        let goalCount = defaults.integer(forKey: goalCountKey) + 1
        defaults.set(goalCount, forKey: goalCountKey)

        guard goalCount >= minimumGoalCount else { return }

        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        let now = Date()
        let lastPrompt = defaults.object(forKey: lastPromptKey) as? Date

        if lastPrompt == nil || now.timeIntervalSince(lastPrompt!) > minimumInterval {
            SKStoreReviewController.requestReview(in: scene)
            defaults.set(now, forKey: lastPromptKey)
        }
    }
}
