//
//  ContentView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import SwiftUI
import SwiftData
import FamilyControls

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var authorizationStatus = "Checking..."
    @State private var showAuthAlert = false

    var body: some View {
        NavigationSplitView {
            List {
                Section("Family Controls Test") {
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
                    .padding(.vertical, 8)
                }

                Section("Items") {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                checkAuthorizationStatus()
            }
            .alert("Authorization Result", isPresented: $showAuthAlert) {
                Button("OK") { }
            } message: {
                Text(authorizationStatus)
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
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
                try await
                AuthorizationCenter.shared.requestAuthorization(for: .individual)
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
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
