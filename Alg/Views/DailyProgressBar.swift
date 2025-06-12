import SwiftUI

struct DailyProgressBar: View {
    @ObservedObject var goalManager: LearningGoalManager
    var showTabBar: Bool
    var isVisible: Bool

    var body: some View {
        if isVisible {
            let progressFraction = max(min(CGFloat(goalManager.learnedToday) / CGFloat(max(goalManager.dailyGoal, 1)), 1.0), 0.0)
            let allColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
            let colorCount = max(Int(round(progressFraction * CGFloat(allColors.count))), 1)
            let visibleColors = Array(allColors.prefix(colorCount))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)

                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: visibleColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: progressFraction * geometry.size.width, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.bottom, 48)
            .allowsHitTesting(false)
            .offset(y: showTabBar ? 0 : 100)
            .opacity(showTabBar ? 1 : 0)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.3), value: showTabBar)
        }
    }
}
