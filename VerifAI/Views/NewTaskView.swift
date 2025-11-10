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
    @State private var selectedDifficulty: TaskDifficulty = .regular

    @State private var showingImagePicker = false
    @State private var showingCameraPicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var showingSourceChoice = false

    @State private var showSavedAlert = false
    @State private var isSaving: Bool = false // Spinner state
    @State private var taskSaved: Bool = false // Track if task is saved
    @State private var showSubmitIteration: Bool = false // Track navigation to SubmitIterationView

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

                    // Card: Difficulty Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How strictly should we evaluate your progress?")
                            .font(.headline)
                            .foregroundColor(.verifAIText)

                        HStack(spacing: 12) {
                            difficultyButton(for: .lenient, label: "Lenient", color: .green)
                            difficultyButton(for: .regular, label: "Regular", color: .yellow)
                            difficultyButton(for: .extreme, label: "Extreme", color: .purple)
                        }

                        // Description for selected difficulty
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedDifficultyLabel())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedDifficultyColor())
                            Text(selectedDifficultyDescription())
                                .font(.caption)
                                .foregroundColor(.verifAIText.opacity(0.7))
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.verifAICard)
                    .cornerRadius(12)

                    // Card: Repetitions & Photo
                    VStack(alignment: .center, spacing: 16) { // Changed alignment to .center
                        HStack {
                            Button {
                                showingSourceChoice = true
                            } label: {
                                VStack {
                                    if let _ = selectedImage {
                                        Image(systemName: "camera")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40) // Adjust size as needed
                                            .foregroundColor(.verifAIAccent)
                                            .frame(maxWidth: .infinity, alignment: .center) // Center image horizontally
                                        Text("Change Photo")
                                            .font(.headline)
                                            .foregroundColor(.verifAIAccent)
                                            .frame(maxWidth: .infinity, alignment: .center) // Center text horizontally
                                    } else {
                                        Image(systemName: "camera")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40) // Adjust size as needed
                                            .foregroundColor(.verifAIAccent)
                                            .frame(maxWidth: 250, alignment: .center) // Center image horizontally
                                        Text("Add Before Photo (Optional)")
                                            .font(.headline)
                                            .foregroundColor(.verifAIAccent)
                                            .frame(maxWidth: 250, alignment: .center)
                                            .multilineTextAlignment(.center) // Center text alignment
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.verifAIAccent)
                            .frame(width: 200) // Restrict button width
                        }
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200) // Match button width
                                .cornerRadius(12)
                                .padding(.top, 8)
                            
                            Button(action: {
                                selectedImage = nil
                            }) {
                                Label("Remove Photo", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color.verifAIBackground)
                            .foregroundColor(.verifAIText)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.verifAICard)
                    .cornerRadius(12)

                    // Card: Save/Cancel
                    VStack(spacing: 12) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .verifAIText))
                                Text("Retrieving Model Response")
                                    .foregroundColor(.verifAIText)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.verifAIAccent)
                            .cornerRadius(10)
                        } else {
                            Button(action: {
                                isSaving = true
                                let prompt = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !prompt.isEmpty else { isSaving = false; return }
                                let beforeData = selectedImage?.jpegData(compressionQuality: 0.85)
                                makeNewTask(
                                    userPrompt: prompt,
                                    iterations: repetitionsOn ? repetitions : 1,
                                    beforeImage: beforeData,
                                    difficulty: selectedDifficulty
                                ) { newTask in
                                    let context = PersistenceController.shared.container.viewContext
                                    saveUserTaskToCoreData(newTask, context: context)

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
                                if taskSaved {
                                    Text("Task Saved")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Label("Save Task", systemImage: "checkmark.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(Color.verifAIAccent)
                            .foregroundColor(.verifAIText)
                            .cornerRadius(10)
                            .disabled(taskSaved) // Gray out after saved
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: showSavedAlert) { newValue in
                        if newValue {
                            isSaving = false
                            taskSaved = true
                            showSubmitIteration = true // Trigger navigation
                        }
                    }
                    .background(
                        NavigationLink(destination: SubmitIterationView(), isActive: $showSubmitIteration) {
                            EmptyView()
                        }
                        .hidden()
                    )
                }
                .padding(.vertical)
            }
            .background(Color.verifAIBackground.ignoresSafeArea())
            .navigationTitle("New Task")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.verifAIBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("Select Photo Source", isPresented: $showingSourceChoice, titleVisibility: .visible) {
                Button("Camera") {
                    showingCameraPicker = true
                }
                Button("Photo Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraPicker(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .alert("Task saved", isPresented: $showSavedAlert) {
                Button("OK") { }
            } message: {
                Text("Saved to sharedTaskList (check console).")
            }
        }
    }

    // MARK: - Difficulty Selector Helpers
    private func difficultyButton(for difficulty: TaskDifficulty, label: String, color: Color) -> some View {
        Button(action: { selectedDifficulty = difficulty }) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectedDifficulty == difficulty ? color.opacity(0.8) : Color.white.opacity(0.2))
            .foregroundColor(.verifAIText)
            .cornerRadius(8)
        }
    }

    private func selectedDifficultyLabel() -> String {
        switch selectedDifficulty {
        case .lenient:
            return "Lenient - Be very forgiving"
        case .regular:
            return "Regular - Be fair and balanced"
        case .extreme:
            return "Extreme - Be very strict"
        }
    }

    private func selectedDifficultyDescription() -> String {
        switch selectedDifficulty {
        case .lenient:
            return "The evaluation will accept any meaningful progress toward your goal."
        case .regular:
            return "The evaluation will check for clear and substantive progress toward your goal."
        case .extreme:
            return "The evaluation will require significant, measurable progress closely following the rubric."
        }
    }

    private func selectedDifficultyColor() -> Color {
        switch selectedDifficulty {
        case .lenient:
            return .green
        case .regular:
            return .yellow
        case .extreme:
            return .purple
        }
    }
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView()
    }
}
