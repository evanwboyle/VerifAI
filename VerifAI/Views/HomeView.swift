//
//  HomeView.swift
//  VerifAI
//

import SwiftUI

struct HomeView: View {
    @State private var showingNewTask = false
    @State private var showingPreviousTasks = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to VerifAI")
                    .font(.title)
                    .padding(.top)

                Button(action: {
                    showingNewTask = true
                }) {
                    Label("Start New Task", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingNewTask) {
                    // Placeholder new task view — replace with your real task creation UI
                    VStack(spacing: 16) {
                        Text("New Task")
                            .font(.title2)
                            .padding(.top)
                        Text("Implement your task creation UI here.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Dismiss") { showingNewTask = false }
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Button(action: {
                    showingPreviousTasks = true
                }) {
                    Label("View Previous Tasks", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingPreviousTasks) {
                    VStack(spacing: 16) {
                        Text("Previous Tasks")
                            .font(.title2)
                            .padding(.top)
                        Text("No previous tasks yet. This is a placeholder.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Dismiss") { showingPreviousTasks = false }
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
