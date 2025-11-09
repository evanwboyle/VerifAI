import SwiftUI
import FamilyControls
import CoreData
import os.log

private let logger = Logger(subsystemName: "RestrictView", category: "View")

struct RestrictView: View {
    // MARK: - Environment
    @EnvironmentObject private var manager: ShieldViewModel
    @Environment(\.managedObjectContext) private var managedObjectContext
    @FetchRequest(
        entity: TaskSettings.entity(),
        sortDescriptors: []
    ) var settings: FetchedResults<TaskSettings>
    
    // MARK: - Restriction State
    @State private var showActivityPicker = false
    @State private var statusMessage = "Not restricting."
    
    // MARK: - Settings State
    @State private var authorizationStatus = "Checking..."
    @State private var showAuthAlert = false
    @State private var defaultTime: Int = 30
    
    // MARK: - Colors
    private let backgroundColor = Color(red: 0x29/255, green: 0x5F/255, blue: 0x50/255)
    private let buttonColor = Color(red: 0x3F/255, green: 0xBC/255, blue: 0x99/255)
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    restrictionStatusCard
                    restrictionPickerSection
                    restrictionControlButtons
                    familyControlsSection
                    defaultTaskSettingsSection
                    resetDataSection
                    Spacer()
                }
                .padding()
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Restrictions & Settings")
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
}

// MARK: - UI Sections
private extension RestrictView {
    var restrictionStatusCard: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Image(systemName: manager.isMonitoring ? "shield.fill" : "shield")
                    .foregroundColor(manager.isMonitoring ? buttonColor : .gray)
                Text("Restriction Status")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text(statusMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .padding(.vertical, 8)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    var restrictionPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Apps to Restrict")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: { showActivityPicker = true }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Choose Apps, Categories & Websites")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .familyActivityPicker(
                isPresented: $showActivityPicker,
                selection: $manager.familyActivitySelection
            )
            
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
                .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    var restrictionControlButtons: some View {
        VStack(spacing: 12) {
            if !manager.isMonitoring {
                Button(action: {
                    manager.shieldActivities()
                    manager.isMonitoring = true
                    statusMessage = "Restrictions applied."
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Restricting")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else {
                Button(action: {
                    manager.unshieldActivities()
                    manager.isMonitoring = false
                    statusMessage = "Restrictions stopped."
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Restricting")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }

            Button(action: {
                manager.clearRestrictions()
                statusMessage = "All restrictions cleared."
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Clear All Restrictions")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    
    var familyControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family Controls")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Authorization Status")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(authorizationStatus)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                
                Button(action: requestAuthorization) {
                    HStack {
                        Image(systemName: "lock.shield")
                        Text("Request Family Controls Authorization")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    var defaultTaskSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Settings")
                .font(.headline)
                .foregroundColor(.white)
            HStack {
                Text("Default Time to Complete Task (minutes)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Stepper(value: $defaultTime, in: 1...240) {
                    Text("\(defaultTime) min")
                        .foregroundColor(.white)
                }
                .onChange(of: defaultTime) { newValue in
                    updateDefaultTime(newValue)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }

    var resetDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
                .foregroundColor(.white)

            Button(action: resetTaskData) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Task Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Logic: Family Controls + Core Data
private extension RestrictView {
    func checkAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        switch status {
        case .notDetermined:
            authorizationStatus = "Not Determined - Tap button to request"
        case .denied:
            authorizationStatus = "Denied - Check Settings"
        case .approved:
            authorizationStatus = "Approved - Family Controls enabled"
        @unknown default:
            authorizationStatus = "Unknown status"
        }
    }

    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                authorizationStatus = "Approved - Family Controls enabled"
                showAuthAlert = true
            } catch FamilyControlsError.invalidAccountType {
                authorizationStatus = "Invalid account type (requires Family setup)"
                showAuthAlert = true
            } catch FamilyControlsError.networkError {
                authorizationStatus = "Network error occurred"
                showAuthAlert = true
            } catch {
                authorizationStatus = "Error: \(error.localizedDescription)"
                showAuthAlert = true
            }
        }
    }

    func loadDefaultTime() {
        if let first = settings.first {
            defaultTime = Int(first.defaultTimeToComplete)
            logger.info("Loaded defaultTimeToComplete = \(defaultTime)")
        } else {
            let newSettings = TaskSettings(context: managedObjectContext)
            newSettings.defaultTimeToComplete = Int32(defaultTime)
            try? managedObjectContext.save()
            logger.info("Created new TaskSettings with defaultTimeToComplete = \(defaultTime)")
        }
    }

    func updateDefaultTime(_ newValue: Int) {
        if let first = settings.first {
            first.defaultTimeToComplete = Int32(newValue)
            try? managedObjectContext.save()
            logger.info("Updated defaultTimeToComplete = \(newValue)")
        } else {
            let newSettings = TaskSettings(context: managedObjectContext)
            newSettings.defaultTimeToComplete = Int32(newValue)
            try? managedObjectContext.save()
            logger.info("Created new TaskSettings with defaultTimeToComplete = \(newValue)")
        }
    }

    func resetTaskData() {
        // Fetch all TaskEntity records and delete them
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        do {
            let allTasks = try managedObjectContext.fetch(fetchRequest)
            for task in allTasks {
                managedObjectContext.delete(task)
            }
            try managedObjectContext.save()
            logger.info("All task data has been reset")
            statusMessage = "All task data has been reset."
        } catch {
            logger.error("Failed to reset task data: \(error.localizedDescription)")
            statusMessage = "Failed to reset task data."
        }
    }
}

#Preview {
    RestrictView()
        .environmentObject(ShieldViewModel())
}
