import SwiftUI
import UIKit
import PhotosUI // Needed for ImagePicker

struct NewTaskView: View {
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
            Form {
                Section(header: Text("Task")) {
                    TextField("Enter task to complete", text: $taskText)
                    Stepper(value: $taskDurationMinutes, in: 1...1440) {
                        Text("Complete after \(taskDurationMinutes) minute\(taskDurationMinutes == 1 ? "" : "s")")
                    }
                }

                Section {
                    Toggle("Repetitions", isOn: $repetitionsOn)
                    if repetitionsOn {
                        Stepper(value: $repetitions, in: 1...100) {
                            Text("How many? \(repetitions)")
                        }
                    }

                    Toggle("Upload before pic?", isOn: $beforePicOn.animation())
                    if beforePicOn {
                        VStack(spacing: 8) {
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 250)
                                    .cornerRadius(8)
                            } else {
                                Text("No photo selected")
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Button {
                                    showingSourceChoice = true
                                } label: {
                                    Label(selectedImage == nil ? "Add Photo" : "Change Photo", systemImage: "camera")
                                }
                                .buttonStyle(.borderedProminent)

                                if selectedImage != nil {
                                    Button(role: .destructive) {
                                        selectedImage = nil
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Save Task") {
                        let prompt = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !prompt.isEmpty else { return }

                        let beforeData = selectedImage?.jpegData(compressionQuality: 0.85)
                        // Create the UserTask
                        let newTask = makeNewTask(
                            userPrompt: prompt,
                            iterations: repetitionsOn ? repetitions : 0,
                            MinsUntilRestricting: taskDurationMinutes,
                            beforeImage: beforeData
                        )
                        // Save to Core Data
                        let context = PersistenceController.shared.container.viewContext
                        saveUserTaskToCoreData(newTask, context: context)

                        // feedback for preview + clear form
                        showSavedAlert = true
                        taskText = ""
                        repetitionsOn = false
                        repetitions = 1
                        selectedImage = nil
                        beforePicOn = false
                    }

                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Task")
            .onAppear {
                if taskDurationMinutes == 0 { taskDurationMinutes = defaultTaskDurationMinutes }
                if allowedAppTimeMinutes == 0 { allowedAppTimeMinutes = defaultAllowedAppTimeMinutes }
            }
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
