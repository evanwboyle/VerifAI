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
    @State private var imageData: Data? = nil
    @State private var isLoading = false
    @State private var isCompleted = false
    @State private var errorMessage: String? = nil
    @State private var showImagePicker = false
    @State private var resultState: String? = nil
    @State private var unlockMessage = false
    @State private var selectedItem: PhotosPickerItem? = nil
    
    // Replace with your actual way of getting the current UserTask
    @State private var userTask: UserTask? = nil
    @State private var debugInfo: String = ""
    
    var body: some View {
        VStack(spacing: 32) {
            if let task = userTask {
                VStack(spacing: 8) {
                    Text(task.userPrompt)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                    // Debug info UI
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rubric: \(task.rubric ?? "nil")")
                        Text("Iterations: \(task.iterations)")
                        Text("IterationSet: \(task.iterationSet.map { $0.currentState ?? "nil" }.joined(separator: ", "))")
                        Text("StartTime: \(task.startTime)")
                        Text("Restricting: \(task.restricting.description)")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            } else {
                Text("No UserTask found.")
                    .foregroundColor(.red)
            }
            if !debugInfo.isEmpty {
                Text(debugInfo)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            // Camera and PhotosPicker are disabled when loading or completed
            if !isCompleted && !isLoading {
                VStack(spacing: 16) {
                    Text("Submit an Image:")
                        .font(.headline)
                    HStack {
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "camera")
                                .font(.system(size: 32))
                        }
                        .disabled(isLoading || isCompleted)
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                        }
                        .disabled(isLoading || isCompleted)
                    }
                }
            }
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Checking Progress...")
                        .font(.headline)
                }
            }
            if isCompleted {
                VStack(spacing: 16) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 40))
                    Text("Completed!")
                        .font(.title)
                    if let state = resultState {
                        Text(state)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    Text("You may now use your restricted apps.")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            // Show failure message if error is due to progress not sufficient
            if let error = errorMessage {
                if error == "Progress not sufficient. Try again." {
                    VStack(spacing: 16) {
                        Image(systemName: "lock")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("You did not complete the task, try again.")
                            .font(.headline)
                            .foregroundColor(.red)
                        if let state = resultState {
                            Text(state)
                                .font(.body)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            print("SubmitIterationView appeared")
            // Attempt to load the latest UserTask from CoreData
            let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
            fetchRequest.fetchLimit = 1
            do {
                let tasks = try context.fetch(fetchRequest)
                if let entity = tasks.first {
                    print("Fetched TaskEntity: \(entity)")
                    // Print all relevant properties
                    print("userPrompt: \(entity.userPrompt ?? "nil")")
                    print("rubric: \(entity.rubric ?? "nil")")
                    print("iterations: \(entity.iterations)")
                    print("startTime: \(entity.startTime?.description ?? "nil")")

                    print("restricting: \(entity.restricting)")
                    // Decode iterationSetData
                    var iterationSet: [Iteration] = []
                    if let data = entity.iterationSetData {
                        if let states = try? JSONDecoder().decode([String?].self, from: data) {
                            iterationSet = states.map { Iteration(currentState: $0) }
                        }
                    }

                    // Check if all iterations have non-nil currentState
                    let hasNoNilIterations = iterationSet.allSatisfy { $0.currentState != nil }
                    if hasNoNilIterations && !iterationSet.isEmpty {
                        // All iterations completed, delete task to switch to NewTaskView
                        context.delete(entity)
                        try context.save()
                        debugInfo = "Task completed. Switched to NewTaskView."
                        return
                    }

                    let loadedTask = UserTask(
                        userPrompt: entity.userPrompt ?? "",
                        rubric: entity.rubric,
                        iterations: Int(entity.iterations),
                        iterationSet: iterationSet,
                        startTime: entity.startTime ?? Date(),
                    )
                    loadedTask.restricting = entity.restricting
                    userTask = loadedTask
                    debugInfo = "Loaded UserTask from CoreData."
                } else {
                    print("No TaskEntity found in CoreData.")
                    debugInfo = "No TaskEntity found in CoreData."
                }
            } catch {
                print("Error fetching TaskEntity: \(error)")
                debugInfo = "Error fetching TaskEntity: \(error.localizedDescription)"
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem)
        .onChange(of: selectedItem) { newItem in
            guard let newItem = newItem else { return }
            print("Image selected for iteration submission")
            isLoading = true
            errorMessage = nil
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    imageData = data
                    if let task = userTask, let imageData = imageData {
                        print("Calling updateTaskWithIteration...")
                        updateTaskWithIteration(task: task, imageData: imageData) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .passed(let isLast, let currentState):
                                    print("Iteration passed. State: \(currentState)")
                                    resultState = currentState
                                    isCompleted = true
                                    unlockMessage = true
                                    manager.clearRestrictions()
                                    saveUserTaskToCoreData(task, context: context)
                                case .failed(let currentState):
                                    print("Iteration failed. State: \(currentState)")
                                    resultState = currentState
                                    errorMessage = "Progress not sufficient. Try again."
                                    isLoading = false
                                    saveUserTaskToCoreData(task, context: context)
                                case .error(let msg):
                                    print("Error: \(msg)")
                                    errorMessage = msg
                                    isLoading = false
                                }
                            }
                        }
                    } else {
                        print("No task or image data available")
                        errorMessage = "No task or image data available."
                        isLoading = false
                    }
                } else {
                    print("Failed to load image data")
                    errorMessage = "Failed to load image data."
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SubmitIterationView()
}
