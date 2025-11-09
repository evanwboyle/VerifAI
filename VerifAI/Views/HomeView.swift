import SwiftUI
import UIKit
import CoreData

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

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isStreak: Bool
}

struct StreakCalendarView: View {
    let days: [CalendarDay]
    let month: Date
    let streakCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(month, style: .date)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Text("     Streak: \(streakCount)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 350) // lock to calendar width
            let weeks = days.chunked(into: 7)
            VStack(spacing: 8) {
                ForEach(weeks.indices, id: \ .self) { weekIndex in
                    HStack(spacing: 8) {
                        ForEach(weeks[weekIndex]) { day in
                            Text("\(Calendar.current.component(.day, from: day.date))")
                                .frame(width: 32, height: 32)
                                .background(day.isStreak ? Color(hex: "#FFA726") : Color.clear)
                                .foregroundColor(day.isStreak ? .black : .white.opacity(0.7))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(hex: "#1A2B2F").opacity(0.7))
            .cornerRadius(16)
            .frame(maxWidth: 350)
        }
        .padding(.vertical)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct HomeView: View {
    @State private var showingNewTask = false
    @State private var showingPreviousTasks = false
    // Hardcoded streak days for Nov 8 and Nov 9, 2025
    private var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let today = Date()
        let monthInterval = calendar.dateInterval(of: .month, for: today)!
        var days: [CalendarDay] = []
        let streakDates: [Date] = [
            calendar.date(from: DateComponents(year: 2025, month: 11, day: 8))!,
            calendar.date(from: DateComponents(year: 2025, month: 11, day: 9))!
        ]
        for offset in 0..<(calendar.range(of: .day, in: .month, for: today)!.count) {
            if let date = calendar.date(byAdding: .day, value: offset, to: monthInterval.start) {
                let isStreak = streakDates.contains { calendar.isDate($0, inSameDayAs: date) }
                days.append(CalendarDay(date: date, isStreak: isStreak))
            }
        }
        return days
    }
    private var currentStreak: Int { 2 }
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to VerifAI")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top)
                // Calendar streak tracker
                StreakCalendarView(days: calendarDays, month: Date(), streakCount: currentStreak)
                NavigationLink(destination: TaskTabSwitcher()) {
                    Label("Start New Task", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#3FBC99"))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
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
