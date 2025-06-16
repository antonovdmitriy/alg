extension Notification.Name {
    static let didDeleteDailyGoal = Notification.Name("didDeleteDailyGoal")
}

//
//  DailyGoalSelectionView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-25.
//

import SwiftUI

public enum DailyGoalSelectionMode {
    case firstLaunch
    case settings
}

struct DailyGoalSelectionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false
    @State private var inputText: String
    @State private var sliderValue: Double
    @State private var showDeleteConfirmation = false
    let mode: DailyGoalSelectionMode
    let allowsDismiss: Bool
    var onGoalSelected: () -> Void

    init(mode: DailyGoalSelectionMode = .settings, allowsDismiss: Bool = true, onGoalSelected: @escaping () -> Void) {
        let storedGoal = UserDefaults.standard.object(forKey: "dailyGoal") != nil
            ? UserDefaults.standard.integer(forKey: "dailyGoal")
            : 10
        _inputText = State(initialValue: "\(storedGoal)")
        _sliderValue = State(initialValue: Double(storedGoal))
        self.mode = mode
        self.allowsDismiss = allowsDismiss
        self.onGoalSelected = onGoalSelected
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("daily_goal_section_title")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(NSLocalizedString("daily_goal_prompt", comment: ""))
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)

                        Slider(value: $sliderValue, in: 1...100, step: 1)
                            .tint(.accentColor)
                            .onChange(of: sliderValue) {
                                inputText = "\(Int(sliderValue))"
                            }

                        HStack(spacing: 8) {
                            TextField("10", text: Binding(
                                get: { inputText },
                                set: { newValue in
                                    inputText = newValue
                                    if let intVal = Int(newValue), intVal >= 1, intVal <= 100 {
                                        sliderValue = Double(intVal)
                                    }
                                })
                            )
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal)

                    Button(action: {
                        dailyGoal = Int(sliderValue)
                        hasSelectedDailyGoal = true
                        withAnimation {
                            onGoalSelected()
                            if allowsDismiss {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        Text(NSLocalizedString("continue_button", comment: ""))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    if mode == .firstLaunch {
                        Button(action: {
                            withAnimation {
                                onGoalSelected()
                                if allowsDismiss {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            Text(NSLocalizedString("continue_without_goal", comment: ""))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    } else {
                        Group {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Text(NSLocalizedString("delete_goal_button", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(hasSelectedDailyGoal ? .red : .gray)
                                    .padding(.top, 8)
                            }
                            .disabled(!hasSelectedDailyGoal)
                        }
                        .alert(isPresented: $showDeleteConfirmation) {
                            Alert(
                                title: Text(NSLocalizedString("confirm_delete_goal_title", comment: "")),
                                message: Text(NSLocalizedString("confirm_delete_goal_message", comment: "")),
                                primaryButton: .destructive(Text(NSLocalizedString("delete_goal_button_yes", comment: ""))) {
                                    UserDefaults.standard.removeObject(forKey: "dailyGoal")
                                    hasSelectedDailyGoal = false
                                    NotificationCenter.default.post(name: .didDeleteDailyGoal, object: nil)
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}
