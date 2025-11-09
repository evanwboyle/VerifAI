import SwiftUI
import FamilyControls
import os.log
import UIKit

struct ContentView: View {
    @StateObject private var manager = ShieldViewModel()
    var body: some View {
        
        TabView {
            // Home Tab
            HomeView()
                .environmentObject(manager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Task Tab
            TaskTabSwitcher()
                .environmentObject(manager)
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
        }
        .onAppear {
            // Configure tab bar with green background and white icons
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Set background color to match background color (#295F50)
            let darkGreenColor = UIColor(red: 0x29/255.0, green: 0x5F/255.0, blue: 0x50/255.0, alpha: 1.0)
            appearance.backgroundColor = darkGreenColor
            
            // Set icon colors to white
            appearance.stackedLayoutAppearance.normal.iconColor = .white
            appearance.stackedLayoutAppearance.selected.iconColor = .white
            
            // Set text colors to white for visibility
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    ContentView()
}
