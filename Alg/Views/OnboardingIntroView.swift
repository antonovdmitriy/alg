import SwiftUI

struct OnboardingIntroView: View {
    @State private var currentPage = 0
    let onFinish: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var gradientColorsForTheme: [[Color]] {
        return [[Color.blue, Color.indigo]]
    }

    private let icons: [String] = [
        "leaf.fill",
        "book.fill",
        "slider.horizontal.3"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: gradientColorsForTheme[currentPage % gradientColorsForTheme.count]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {
                onboardingPage(
                    title: String(localized: "onboarding.welcome.title"),
                    text: String(localized: "onboarding.welcome.text"),
                    tag: 0
                )
                onboardingPage(
                    title: String(localized: "onboarding.features.title"),
                    text: String(localized: "onboarding.features.text"),
                    tag: 1
                )
                onboardingPage(
                    title: String(localized: "onboarding.settings.title"),
                    text: String(localized: "onboarding.settings.text"),
                    tag: 2,
                    isLast: true
                )
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }

    private func onboardingPage(title: String, text: String, tag: Int, isLast: Bool = false) -> some View {
        let textColor = Color.white

        return ZStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: icons[tag % icons.count])
                    .font(.system(size: 64))
                    .foregroundColor(textColor)
                    .padding(.bottom, 12)
                    .scaleEffect(currentPage == tag ? 1.1 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: currentPage)
                Text(title)
                    .font(colorScheme == .dark ? .largeTitle.bold() : .title2.weight(.regular))
                    .foregroundColor(textColor)
                Text(text)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                    .padding(.horizontal)
                Spacer()
                if isLast {
                    Button(String(localized: "onboarding.continue.button")) {
                        onFinish()
                    }
                    .font(.headline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3))
                    )
                    .foregroundColor(textColor)
                    .cornerRadius(12)
                }
                Spacer().frame(height: 40)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .tag(tag)
    }
}
