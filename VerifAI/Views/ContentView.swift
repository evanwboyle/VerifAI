//
//  ContentView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import SwiftUI
import FamilyControls
import os.log

struct ContentView: View {
    @StateObject private var manager = ShieldViewModel()
    var body: some View {
        
        TabView {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Camera Tab
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }

            // New Task Tab
            NewTaskView()
                .tabItem {
                    Label("Task", systemImage: "plus.circle.fill")
                }

            // Restrict Tab
            RestrictView()
                .environmentObject(manager)
                .task(id: "requestAuthorizationTaskID") {
                    await manager.requestAuthorization()
                }
                .tabItem {
                    Label("Restrict", systemImage: "shield.fill")
                
                }

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
