
import SwiftUI

struct OnboardingIntroView: View {
    @State private var currentPage = 0
    let onFinish: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var gradientColorsForTheme: [[Color]] {
        return [
            [Color.blue, Color.purple],
            [Color.indigo, Color.teal],
            [Color.pink, Color.orange]
        ]
    }

    private let icons: [String] = [
        "leaf.fill",
        "slider.horizontal.3",
        "book.fill"
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
                    title: "Добро пожаловать",
                    text: """
Älg — это пространство, где можно учить шведский язык без давления в любой форме.

Оно создано с уважением к твоему уникальному пути, твоему стилю изучения нового.

Здесь никто не будет тебя сравнивать или подгонять.
""",
                    tag: 0
                )
                onboardingPage(
                    title: "Слова, примеры и игра",
                    text: "В приложении есть словарь с примерами, игра на сопоставление и режим случайного слова. Можно сосредоточиться на том, что тебе сейчас интересно.",
                    tag: 1
                )
                onboardingPage(
                    title: "Настройки",
                    text: "Ненужные, выученные или просто нелюбимые слова можно убрать. Любимые — отметить. Почти всё можно изменить в настройках, если захочется.",
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
                    Button("Продолжить") {
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
