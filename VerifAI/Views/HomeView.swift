import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

struct HomeView: View {
    @State private var showingNewTask = false
    @State private var showingPreviousTasks = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to VerifAI")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top)

                Button(action: {
                    showingNewTask = true
                }) {
                    Label("Start New Task", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#3FBC99"))
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
                        .background(Color(hex: "#3FBC99"))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#295F50"))
            .navigationTitle("Home")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "#295F50"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}