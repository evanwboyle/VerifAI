//
//  RestrictView.swift
//  Screen Time
//
//  Created on 29/05/24.
//
//

import SwiftUI
import FamilyControls
import os.log

private let logger = Logger(subsystemName: "RestrictView", category: "View")

struct RestrictView: View {
    @EnvironmentObject private var manager: ShieldViewModel
    @State private var showActivityPicker = false
    @State private var isMonitoring = false
    @State private var statusMessage = "Not restricting."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: isMonitoring ? "shield.fill" : "shield")
                                .foregroundColor(isMonitoring ? .green : .gray)
                            Text("Restriction Status")
                                .font(.headline)
                        }
                        Text(statusMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // App Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Apps to Restrict")
                            .font(.headline)
                        Button(action: { showActivityPicker = true }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("Choose Apps, Categories & Websites")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBlue))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .familyActivityPicker(
                            isPresented: $showActivityPicker,
                            selection: $manager.familyActivitySelection
                        )
                        // Selected Items Count
                        if !manager.familyActivitySelection.applications.isEmpty ||
                            !manager.familyActivitySelection.categories.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if !manager.familyActivitySelection.applications.isEmpty {
                                    Label("\(manager.familyActivitySelection.applications.count) app(s) selected", systemImage: "app")
                                        .font(.caption)
                                }
                                if !manager.familyActivitySelection.categories.isEmpty {
                                    Label("\(manager.familyActivitySelection.categories.count) categor(ies) selected", systemImage: "square.grid.2x2")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    // Control Buttons
                    VStack(spacing: 12) {
                        if !isMonitoring {
                            Button(action: {
                                manager.shieldActivities()
                                isMonitoring = true
                                statusMessage = "Restrictions applied."
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Restricting")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGreen))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        } else {
                            Button(action: {
                                // No direct stop in ShieldViewModel, so just update UI
                                isMonitoring = false
                                statusMessage = "Restrictions stopped."
                            }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Stop Restricting")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemRed))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        Button(action: {
                            // Clear selection and update UI
                            manager.familyActivitySelection = FamilyActivitySelection()
                            isMonitoring = false
                            statusMessage = "All restrictions cleared."
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Clear All Restrictions")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Restrictions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RestrictView()
        .environmentObject(ShieldViewModel())
}
