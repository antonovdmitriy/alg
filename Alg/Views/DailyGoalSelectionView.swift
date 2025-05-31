//
//  DailyGoalSelectionView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-25.
//

import SwiftUI

struct DailyGoalSelectionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @State private var inputText: String
    @State private var sliderValue: Double
    let allowsDismiss: Bool
    var onGoalSelected: () -> Void

    init(allowsDismiss: Bool = true, onGoalSelected: @escaping () -> Void) {
        let storedGoal = UserDefaults.standard.object(forKey: "dailyGoal") != nil
            ? UserDefaults.standard.integer(forKey: "dailyGoal")
            : 10
        _inputText = State(initialValue: "\(storedGoal)")
        _sliderValue = State(initialValue: Double(storedGoal))
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
                                        dailyGoal = intVal
                                    }
                                })
                            )
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)

                            Text(NSLocalizedString("words", comment: ""))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    Button(action: {
                        dailyGoal = Int(sliderValue)
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
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}
