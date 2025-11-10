//
//  SubmitIterationView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/8/25.
//

import SwiftUI
import CoreData
import PhotosUI
import FamilyControls

struct SubmitIterationView: View {
    @EnvironmentObject private var manager: ShieldViewModel
    @Environment(\.managedObjectContext) private var context
    @State private var isLoading = false
    @State private var isCompleted = false
    @State private var isSuccessful = false
    @State private var errorMessage: String? = nil
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showingSourceChoice = false
    @State private var resultState: String? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var userTask: UserTask? = nil
    @State private var timeActive: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Prompt Card
                    if let task = userTask {
                        VStack(spacing: 12) {
                            Text(task.userPrompt)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.verifAIText)
                                .multilineTextAlignment(.center)

                            Text(timeActive)
                                .font(.caption)
                                .foregroundColor(.verifAIText.opacity(0.7))
                        }
                        .padding()
                        .background(Color.verifAICard)
                        .cornerRadius(12)
                    }

                    // Lock Status Card
                    lockStatusCard

                    // Photo Preview or Submission Card
                    if selectedImage != nil {
                        photoPreviewCard
                    } else if !isCompleted {
                        imageSubmissionCard
                    }

                    // Result Card (only show after completion)
                    if isCompleted {
                        resultCard
                    }

                    // Error Card
                    if let error = errorMessage, error != "Progress not sufficient. Try again." {
                        errorCard(message: error)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.verifAIBackground.ignoresSafeArea())
            .navigationTitle("Submit Progress")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.verifAIBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            loadUserTask()
            startTimeTracking()
        }
        .confirmationDialog("Select Photo Source", isPresented: $showingSourceChoice, titleVisibility: .visible) {
            Button("Camera") {
                showCameraPicker = true
            }
            Button("Photo Library") {
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(image: $selectedImage)
                .ignoresSafeArea()
        }
    }
}

// MARK: - UI Sections
private extension SubmitIterationView {
    var lockStatusCard: some View {
        VStack(alignment: .center, spacing: 12) {
            if isCompleted && isSuccessful {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.verifAIAccent)
                Text("Apps Unlocked!")
                    .font(.headline)
                    .foregroundColor(.verifAIText)
                Text("Great work—you've completed the task!")
                    .font(.body)
                    .foregroundColor(.verifAIText.opacity(0.8))
            } else if isCompleted && !isSuccessful {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red.opacity(0.7))
                Text("Apps Still Locked")
                    .font(.headline)
                    .foregroundColor(.verifAIText)
                Text("You didn't complete the task yet. Keep trying!")
                    .font(.body)
                    .foregroundColor(.verifAIText.opacity(0.8))
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .verifAIAccent))
                    .scaleEffect(1.5)
                Text("Analyzing your progress...")
                    .font(.headline)
                    .foregroundColor(.verifAIText)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.verifAIAccent)
                Text("Apps Locked Until You Complete the Task")
                    .font(.headline)
                    .foregroundColor(.verifAIText)
                Text("Submit evidence of your progress to unlock")
                    .font(.body)
                    .foregroundColor(.verifAIText.opacity(0.8))
            }
        }
        .padding()
        .background(Color.verifAICard)
        .cornerRadius(12)
    }

    var imageSubmissionCard: some View {
        VStack(spacing: 16) {
            Text("Submit Evidence")
                .font(.headline)
                .foregroundColor(.verifAIText)

            Button(action: { showingSourceChoice = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose Photo or Take Picture")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.verifAIAccent)
                .foregroundColor(.verifAIText)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.verifAICard)
        .cornerRadius(12)
    }

    var photoPreviewCard: some View {
        VStack(spacing: 16) {
            Text("Evidence Preview")
                .font(.headline)
                .foregroundColor(.verifAIText)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            }

            VStack(spacing: 12) {
                Button(action: { showingSourceChoice = true }) {
                    Label("Change Photo", systemImage: "arrow.2.squarepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.verifAIAccent)
                .foregroundColor(.verifAIText)
                .cornerRadius(10)
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)

                Button(action: { selectedImage = nil }) {
                    Label("Remove Photo", systemImage: "trash")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .foregroundColor(.verifAIText)
                .cornerRadius(10)
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)

                if !isLoading {
                    Button(action: { handleImageSelection(selectedImage) }) {
                        Label("Submit", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.green.opacity(0.7))
                    .foregroundColor(.verifAIText)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.verifAICard)
        .cornerRadius(12)
    }

    var resultCard: some View {
        VStack(spacing: 16) {
            if isSuccessful {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.verifAIAccent)
                Text("Task Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.verifAIText)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red.opacity(0.7))
                Text("Not Complete Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.verifAIText)
            }

            if let state = resultState {
                Text(state)
                    .font(.body)
                    .foregroundColor(.verifAIText.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            if !isSuccessful {
                Button(action: {
                    selectedImage = nil
                    isCompleted = false
                    resultState = nil
                    errorMessage = nil
                }) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.verifAIAccent)
                .foregroundColor(.verifAIText)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.verifAICard)
        .cornerRadius(12)
    }

    func errorCard(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.7))
            Text("Error")
                .font(.headline)
                .foregroundColor(.verifAIText)
            Text(message)
                .font(.body)
                .foregroundColor(.verifAIText.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.verifAICard)
        .cornerRadius(12)
    }
}

// MARK: - Logic
private extension SubmitIterationView {
    func loadUserTask() {
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let tasks = try context.fetch(fetchRequest)
            if let entity = tasks.first {
                var iterationSet: [Iteration] = []
                if let data = entity.iterationSetData {
                    if let states = try? JSONDecoder().decode([String?].self, from: data) {
                        iterationSet = states.map { Iteration(currentState: $0) }
                    }
                }

                let hasNoNilIterations = iterationSet.allSatisfy { $0.currentState != nil }
                if hasNoNilIterations && !iterationSet.isEmpty {
                    context.delete(entity)
                    try context.save()
                    return
                }

                let difficulty = TaskDifficulty(rawValue: entity.difficulty ?? "regular") ?? .regular
                let loadedTask = UserTask(
                    userPrompt: entity.userPrompt ?? "",
                    rubric: entity.rubric,
                    iterations: Int(entity.iterations),
                    iterationSet: iterationSet,
                    startTime: entity.startTime ?? Date(),
                    difficulty: difficulty
                )
                loadedTask.restricting = entity.restricting
                userTask = loadedTask
            }
        } catch {
            print("Error fetching TaskEntity: \(error)")
        }
    }

    func startTimeTracking() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let task = userTask {
                let elapsed = Date().timeIntervalSince(task.startTime)
                let minutes = Int(elapsed) / 60
                let seconds = Int(elapsed) % 60
                timeActive = "Active for \(minutes)m \(seconds)s"
            }
        }
    }

    func handleImageSelection(_ image: UIImage?) {
        guard let image = image else { return }

        isLoading = true
        errorMessage = nil

        if let imageData = image.jpegData(compressionQuality: 0.85),
           let task = userTask {
            print("Processing image for iteration submission")
            updateTaskWithIteration(task: task, imageData: imageData) { result in
                DispatchQueue.main.async {
                    defer { isLoading = false }

                    switch result {
                    case .passed(let _, let currentState):
                        print("Iteration passed")
                        resultState = currentState
                        isSuccessful = true
                        isCompleted = true
                        manager.clearRestrictions()
                        saveUserTaskToCoreData(task, context: context)
                    case .failed(let currentState):
                        print("Iteration failed")
                        resultState = currentState
                        isSuccessful = false
                        isCompleted = true
                        saveUserTaskToCoreData(task, context: context)
                    case .error(let msg):
                        print("Error: \(msg)")
                        errorMessage = msg
                    }
                }
            }
        } else {
            errorMessage = "Failed to process image"
            isLoading = false
        }
    }
}

#Preview {
    SubmitIterationView()
}
