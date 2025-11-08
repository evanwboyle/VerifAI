//
//  RestrictView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import SwiftUI
import FamilyControls

struct RestrictView: View {
    @StateObject private var manager = RestrictionsManager.shared
    @State private var showActivityPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: manager.isMonitoring ? "shield.fill" : "shield")
                                .foregroundColor(manager.isMonitoring ? .green : .gray)
                            Text("Restriction Status")
                                .font(.headline)
                        }

                        Text(manager.statusMessage)
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
                            selection: $manager.activitySelection
                        )

                        // Selected Items Count
                        if !manager.activitySelection.applications.isEmpty ||
                            !manager.activitySelection.categories.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if !manager.activitySelection.applications.isEmpty {
                                    Label("\(manager.activitySelection.applications.count) app(s) selected", systemImage: "app")
                                        .font(.caption)
                                }
                                if !manager.activitySelection.categories.isEmpty {
                                    Label("\(manager.activitySelection.categories.count) categor(ies) selected", systemImage: "square.grid.2x2")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    // Control Buttons
                    VStack(spacing: 12) {
                        if !manager.isMonitoring {
                            Button(action: {
                                manager.configureRestrictions()
                                Task {
                                    await manager.startMonitoring()
                                }
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
                                Task {
                                    await manager.stopMonitoring()
                                }
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
                            manager.clearRestrictions()
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
}
