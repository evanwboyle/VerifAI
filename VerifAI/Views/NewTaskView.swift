//
//  NewTaskView.swift
//  VerifAI
//
//

import SwiftUI

struct NewTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var taskText: String = ""
    @State private var repetitionsOn: Bool = false
    @State private var repetitions: Int = 1
    @State private var beforePicOn: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task")) {
                    TextField("Enter task to complete", text: $taskText)
                    HStack {
                        Text("Complete after")
                        Spacer()
                        Text("7 minutes")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Toggle("Repetitions", isOn: $repetitionsOn)
                    if repetitionsOn {
                        Stepper(value: $repetitions, in: 1...100) {
                            Text("How many? \(repetitions)")
                        }
                    }

                    Toggle("Upload before pic", isOn: $beforePicOn)
                    if beforePicOn {
                        Button(action: {
                            // placeholder for photo picker integration
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose before photo")
                            }
                        }
                    }
                }

                Section {
                    Button("Save Task") {
                        // TODO: implement save logic
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Task")
        }
    }
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView()
    }
}