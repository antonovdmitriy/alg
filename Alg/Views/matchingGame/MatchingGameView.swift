import SwiftUI

struct MatchingGameView: View {
    @Binding var showTabBar: Bool
    @State private var lastTapDate: Date = .distantPast
    private let tapThreshold: TimeInterval = 0.4

    let wordService: WordService
    let learningStateManager: WordLearningStateManager

    @StateObject private var viewModel: MatchingGameViewModel
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("selectedLanguageLevel") private var selectedLanguageLevel = "all"
    @AppStorage("includeLowerLevels") private var includeLowerLevels = true
    @EnvironmentObject var visualStyleManager: VisualStyleManager
    
    init(showTabBar: Binding<Bool>, wordService: WordService, learningStateManager: WordLearningStateManager) {
        self._showTabBar = showTabBar
        _viewModel = StateObject(wrappedValue: MatchingGameViewModel(wordService: wordService, learningStateManager: learningStateManager))
        self.wordService = wordService
        self.learningStateManager = learningStateManager
    }

    var body: some View {
        ZStack {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                if visualStyleManager.useSolidColorBackground {
                    AnimatedColorBackground(palettes: [
                        [Color(red: 0.1, green: 0.15, blue: 0.25)],
                        [Color(red: 0.05, green: 0.2, blue: 0.15)],
                        [Color(red: 0.2, green: 0.1, blue: 0.3)],
                        [Color(red: 0.1, green: 0.05, blue: 0.2)],
                        [Color(red: 0.15, green: 0.1, blue: 0.2)],
                        [Color(red: 0.1, green: 0.15, blue: 0.1)],
                        [Color(red: 0.1, green: 0.1, blue: 0.2)],
                        [Color(red: 0.12, green: 0.1, blue: 0.25)],
                        [Color(red: 0.1, green: 0.2, blue: 0.3)],
                        [Color(red: 0.08, green: 0.1, blue: 0.15)],
                        [Color(red: 0.05, green: 0.1, blue: 0.2)],
                        [Color(red: 0.2, green: 0.15, blue: 0.25)],
                        [Color(red: 0.15, green: 0.15, blue: 0.15)],
                    ])
                } else {
                    AnimatedGradientBackground(palettes: [
                        [Color.black, Color.cyan, Color.indigo],
                        [Color.black, Color.orange, Color.purple, Color.blue],
                        [Color.black, Color.blue, Color.mint],
                        [Color.black, Color.cyan, Color.green],
                        [Color.black, Color.mint, Color.yellow],
                        [Color.black, Color.indigo, Color.teal],
                        [Color.black, Color.blue, Color.pink],
                        [Color.black, Color.orange, Color.mint],
                        [Color.black, Color.purple, Color.cyan],
                        [Color.black, Color.green.opacity(0.6), Color.blue.opacity(0.7), Color.purple.opacity(0.8)],
                        [Color.black, Color.indigo, Color.purple, Color.red.opacity(0.6)],
                        [Color.black, Color.cyan, Color.mint, Color.white.opacity(0.3)],
                        [Color.black, Color.pink.opacity(0.5), Color.purple.opacity(0.5), Color.teal.opacity(0.6)],
                    ])
                }
            } else {
                if visualStyleManager.useSolidColorBackground {
                    AnimatedColorBackground(palettes: [
                        [Color(red: 1.0, green: 0.9, blue: 0.85)],
                        [Color(red: 0.9, green: 0.95, blue: 0.8)],
                        [Color(red: 0.85, green: 0.95, blue: 1.0)],
                        [Color(red: 0.9, green: 1.0, blue: 0.9)],
                        [Color(red: 0.95, green: 0.85, blue: 0.8)],
                        [Color(red: 0.9, green: 0.9, blue: 1.0)],
                        [Color(red: 1.0, green: 0.85, blue: 0.95)],
                        [Color(red: 0.95, green: 0.9, blue: 1.0)],
                        [Color(red: 0.9, green: 1.0, blue: 1.0)],
                        [Color(red: 0.85, green: 0.9, blue: 0.95)],
                    ])
                } else {
                    AnimatedGradientBackground(palettes: [
                        [.pink, .orange, .yellow],
                        [.mint, .teal, .blue],
                        [.cyan, .indigo, .purple],
                        [.green, .mint],
                        [.orange, .red],
                        [.yellow, .green, .blue],
                        [.teal, .cyan],
                        [.purple, .pink, .mint],
                        [.blue, .indigo, .teal],
                        [.orange, .yellow, .mint],
                        [.red, .orange, .pink],
                        [.blue, .purple, .mint],
                        [.mint, .teal, .pink],
                        [.cyan, .green, .yellow],
                        [.orange, .mint, .blue],
                        [.purple, .cyan, .mint],
                        [.indigo, .purple, .red],
                        [.yellow, .cyan, .pink],
                        [.green, .blue, .mint],
                        [.pink, .yellow],
                        [.mint, .green, .yellow],
                        [.indigo, .purple],
                        [.cyan, .blue],
                        [.yellow, .mint, .green],
                        [.teal, .blue],
                        [.green, .cyan],
                        [.indigo, .mint, .teal],
                        [.orange, .indigo],
                        [.cyan, .pink, .mint],
                        [.green, .blue, .mint],
                        [.pink, .purple, .yellow]
                    ])
                }
            }

            GeometryReader { geometry in
                let bottomSafeArea = geometry.safeAreaInsets.bottom
                VStack {
                    Spacer().frame(height: (geometry.size.height - bottomSafeArea) * 0.25)

                    HStack(alignment: .top, spacing: 30) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.leftColumn) { pair in
                                if !pair.isMatched {
                                    let isSelected = viewModel.selectedLeft?.id == pair.id
                                    let isLight = UITraitCollection.current.userInterfaceStyle == .light
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(.clear)
                                            .contentShape(Rectangle())
                                        Text(pair.left)
                                            .font(.system(size: 20, weight: .regular))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 75, maxHeight: 75)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                (UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground)
                                                    ? Color.clear
                                                    : (UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground)
                                                        ? Color.clear
                                                        : isSelected && isLight && !visualStyleManager.useSolidColorBackground
                                                            ? Color.accentColor.opacity(0.2)
                                                            : Color(UIColor {
                                                                $0.userInterfaceStyle == .dark
                                                                    ? UIColor.systemGray5
                                                                    : UIColor.systemGray6
                                                            })
                                            )
                                    )
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                                    .overlay(
                                        Group {
                                            if UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        isSelected ? Color.white : Color.white.opacity(0.25),
                                                        lineWidth: 2
                                                    )
                                            } else if UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        isSelected ? Color.primary : Color.primary.opacity(0.25),
                                                        lineWidth: 1
                                                    )
                                            } else if !(isLight && !visualStyleManager.useSolidColorBackground) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        isSelected
                                                            ? Color.accentColor.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 1 : 0.4)
                                                            : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            }
                                        }
                                    )
                                    .shadow(color:
                                        (isSelected && UITraitCollection.current.userInterfaceStyle == .dark)
                                            ? Color.accentColor.opacity(0.4)
                                            : Color.clear,
                                        radius: (isSelected && UITraitCollection.current.userInterfaceStyle == .dark) ? 6 : 0,
                                        x: 0, y: 0
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                    .onTapGesture {
                                        viewModel.select(pair: pair, isLeft: true)
                                    }
                                }
                            }
                        }
                        VStack(spacing: 12) {
                            ForEach(viewModel.rightColumn) { pair in
                                if !pair.isMatched {
                                    let isSelected = viewModel.selectedRight?.id == pair.id
                                    let isLight = UITraitCollection.current.userInterfaceStyle == .light
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .contentShape(Rectangle())
                                    Text(pair.right)
                                        .font(.system(size: 20, weight: .regular))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 75, maxHeight: 75)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                (UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground)
                                                    ? Color.clear
                                                    : (UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground)
                                                        ? Color.clear
                                                        : isSelected && isLight && !visualStyleManager.useSolidColorBackground
                                                            ? Color.accentColor.opacity(0.2)
                                                            : Color(UIColor {
                                                                $0.userInterfaceStyle == .dark
                                                                    ? UIColor.systemGray5
                                                                    : UIColor.systemGray6
                                                            })
                                            )
                                    )
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                                    .overlay(
                                        Group {
                                            if UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        isSelected ? Color.white : Color.white.opacity(0.25),
                                                        lineWidth: 2
                                                    )
                                            } else if UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        isSelected ? Color.primary : Color.primary.opacity(0.25),
                                                        lineWidth: 1
                                                    )
                                            } else if !(isLight && !visualStyleManager.useSolidColorBackground) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        isSelected
                                                            ? Color.accentColor.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 1 : 0.4)
                                                            : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            }
                                        }
                                    )
                                    .shadow(color:
                                        (isSelected && UITraitCollection.current.userInterfaceStyle == .dark)
                                            ? Color.accentColor.opacity(0.4)
                                            : Color.clear,
                                        radius: (isSelected && UITraitCollection.current.userInterfaceStyle == .dark) ? 6 : 0,
                                        x: 0, y: 0
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                    .onTapGesture {
                                        viewModel.select(pair: pair, isLeft: false)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.pairs)
                .onChange(of: selectedLanguage) {
                    viewModel.generatePairs(preserveIds: true)
                }
                .onChange(of: selectedCategoriesData) {
                    viewModel.generatePairs(preserveIds: true)
                }
                .onChange(of: selectedLanguageLevel) {
                    viewModel.generatePairs(preserveIds: false)
                }
                .onChange(of: includeLowerLevels) {
                    viewModel.generatePairs(preserveIds: false)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onTapGesture {
            let now = Date()
            if now.timeIntervalSince(lastTapDate) > tapThreshold {
                lastTapDate = now
                withAnimation {
                    showTabBar.toggle()
                }
            }
        }
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
    }
}
