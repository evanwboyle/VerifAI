//
//  SettingsView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import SwiftUI
import FamilyControls
import SwiftData

struct SettingsView: View {
    @State private var authorizationStatus = "Checking..."
    @State private var showAuthAlert = false
    @Environment(\.modelContext) private var modelContext
    @Query var settings: [TaskSettings]
    @State private var defaultTime: Int = 30

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Family Controls Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Family Controls")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Authorization Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(authorizationStatus)
                                .font(.body)
                                .padding(.vertical, 4)

                            Button(action: requestAuthorization) {
                                HStack {
                                    Image(systemName: "lock.shield")
                                    Text("Request Family Controls Authorization")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Default Time Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Task Settings")
                            .font(.headline)
                        HStack {
                            Text("Default Time to Complete Task (minutes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper(value: $defaultTime, in: 1...240) {
                                Text("\(defaultTime) min")
                            }
                            .onChange(of: defaultTime) { newValue in
                                updateDefaultTime(newValue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkAuthorizationStatus()
                loadDefaultTime()
            }
            .alert("Authorization Result", isPresented: $showAuthAlert) {
                Button("OK") { }
            } message: {
                Text(authorizationStatus)
            }
        }
    }

    private func checkAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        switch status {
        case .notDetermined:
            authorizationStatus = "Not Determined - Tap button to request"
        case .denied:
            authorizationStatus = "❌ Denied - Check Settings"
        case .approved:
            authorizationStatus = "✅ Approved - Family Controls enabled!"
        @unknown default:
            authorizationStatus = "Unknown status"
        }
    }

    private func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                authorizationStatus = "✅ Approved - Family Controls enabled!"
                showAuthAlert = true
            } catch FamilyControlsError.invalidAccountType {
                authorizationStatus = "❌ Error: Invalid account type (not a child account or needs family setup)"
                showAuthAlert = true
            } catch FamilyControlsError.networkError {
                authorizationStatus = "❌ Error: Network error occurred"
                showAuthAlert = true
            } catch {
                authorizationStatus = "❌ Error: \(error.localizedDescription)"
                showAuthAlert = true
            }
        }
    }

    private func loadDefaultTime() {
        if let first = settings.first {
            defaultTime = first.defaultTimeToComplete
            print("SettingsView: Loaded defaultTimeToComplete =", defaultTime)
        } else {
            let newSettings = TaskSettings(defaultTimeToComplete: defaultTime)
            modelContext.insert(newSettings)
            print("SettingsView: Created new TaskSettings with defaultTimeToComplete =", defaultTime)
        }
    }

    private func updateDefaultTime(_ newValue: Int) {
        if let first = settings.first {
            first.defaultTimeToComplete = newValue
            print("SettingsView: Updated defaultTimeToComplete to", newValue)
        } else {
            let newSettings = TaskSettings(defaultTimeToComplete: newValue)
            modelContext.insert(newSettings)
            print("SettingsView: Created new TaskSettings with defaultTimeToComplete =", newValue)
        }
    }
}

#Preview {
    SettingsView()
}
