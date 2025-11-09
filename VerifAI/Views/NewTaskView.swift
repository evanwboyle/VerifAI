import SwiftUI
import UIKit
import PhotosUI // Needed for ImagePicker

// MARK: - Color Extensions
extension Color {
    static let verifAIBackground = Color(hexString: "#295F50")
    static let verifAIAccent = Color(hexString: "#3FBC99")
    static let verifAICard = Color.white.opacity(0.1)
    static let verifAIText = Color.white
    // Use a unique name for the initializer to avoid ambiguity
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct NewTaskView: View {
    @EnvironmentObject private var manager: ShieldViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("defaultTaskDurationMinutes") private var defaultTaskDurationMinutes: Int = 7
    @AppStorage("defaultAllowedAppTimeMinutes") private var defaultAllowedAppTimeMinutes: Int = 5

    @State private var taskText: String = ""
    @State private var repetitionsOn: Bool = false
    @State private var repetitions: Int = 1
    @State private var beforePicOn: Bool = false
    @State private var taskDurationMinutes: Int = 0
    @State private var allowedAppTimeMinutes: Int = 0

    @State private var showingImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary // Can be removed if not needed
    @State private var selectedImage: UIImage? = nil
    @State private var showingSourceChoice = false

    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card: Task Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What do you want to achieve today?")
                            .font(.headline)
                            .foregroundColor(.verifAIText)
                        TextField("Enter task to complete", text: $taskText)
                            .padding(8)
                            .background(Color.verifAICard)
                            .cornerRadius(8)
                            .foregroundColor(.verifAIText)
                    
    
                    }
                    .padding()
                    .background(Color.verifAICard)
                    .cornerRadius(12)

                    // Card: Repetitions & Photo
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button {
                                showingSourceChoice = true
                            } label: {
                                Label("Add Before Photo (Optional)", systemImage: "camera")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.verifAIAccent)
                        }
                    }
                    .padding()
                    .background(Color.verifAICard)
                    .cornerRadius(12)

                    // Card: Save/Cancel
                    VStack(spacing: 12) {
                        Button(action: {
                            let prompt = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !prompt.isEmpty else { return }
                            let beforeData = selectedImage?.jpegData(compressionQuality: 0.85)
                            makeNewTask(
                                userPrompt: prompt,
                                iterations: repetitionsOn ? repetitions : 1,
                                beforeImage: beforeData
                            ) { newTask in
                                let context = PersistenceController.shared.container.viewContext
                                saveUserTaskToCoreData(newTask, context: context)

                                // Start restricting apps if any are selected
                                if !manager.familyActivitySelection.applications.isEmpty ||
                                   !manager.familyActivitySelection.categories.isEmpty {
                                    manager.shieldActivities()
                                    manager.isMonitoring = true
                                }

                                showSavedAlert = true
                                taskText = ""
                                repetitionsOn = false
                                repetitions = 1
                                selectedImage = nil
                                beforePicOn = false
                            }
                        }) {
                            Label("Save Task", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.verifAIAccent)
                        .foregroundColor(.verifAIText)
                        .cornerRadius(10)
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.verifAIText)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.verifAIBackground.ignoresSafeArea())
            .navigationTitle("New Task")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.verifAIBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("Select Photo Source", isPresented: $showingSourceChoice, titleVisibility: .visible) {
                Button("Photo Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .alert("Task saved", isPresented: $showSavedAlert) {
                Button("OK") { }
            } message: {
                Text("Saved to sharedTaskList (check console).")
            }
        }
    }
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView()
    }
}
