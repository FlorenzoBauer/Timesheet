import SwiftUI
import SwiftData

struct MonthlySummaryView: View {
    let job: Job
    @State private var selectedMonth = Date() // Starts at current month
    
    // UI Colors from your ContentView
    let blushPink = Color(red: 1.0, green: 0.92, blue: 0.93)
    let accentPink = Color(red: 0.95, green: 0.75, blue: 0.78)
    let textDark = Color(red: 0.4, green: 0.3, blue: 0.32)

    var body: some View {
        VStack(spacing: 0) {
            // Header with Month Navigation
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title2)
                }
                
                Spacer()
                
                Text(selectedMonth.format("MMMM yyyy"))
                    .font(.headline)
                    .foregroundColor(textDark)
                
                Spacer()
                
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
            }
            .padding()
            .background(accentPink.opacity(0.5))
            .tint(textDark)

            List {
                let weeks = weeksInMonth(for: selectedMonth)
                
                ForEach(weeks, id: \.self) { weekStart in
                    let stats = statsForWeek(weekStart)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Week of \(weekStart.format("MMM d"))")
                                .font(.subheadline).bold()
                            Text("\(stats.hours, specifier: "%.1f") hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(stats.pay, format: .currency(code: "USD"))
                            .font(.system(.body, design: .monospaced))
                            .bold()
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(blushPink.opacity(0.2))
                }
            }
            .listStyle(.insetGrouped)
            
            // Total Monthly Footer
            VStack(spacing: 4) {
                Divider()
                HStack {
                    Text("Monthly Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(monthlyTotal().pay, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.black)
                }
                .padding()
            }
            .background(Color.white)
            .foregroundColor(textDark)
        }
    }

    // MARK: - Calculations
    
    private func moveMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func weeksInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }
        
        var weeks: [Date] = []
        let days = Array(monthRange)
        
        for day in days {
            if let dateInMonth = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let weekStart = calendar.startOfWeek(for: dateInMonth)
                if !weeks.contains(weekStart) {
                    weeks.append(weekStart)
                }
            }
        }
        return weeks.sorted()
    }

    private func statsForWeek(_ weekStart: Date) -> (hours: Double, pay: Double) {
        let entries = job.entries.filter { Calendar.current.isDate($0.date, inSameWeekAs: weekStart) }
        let totalSeconds = entries.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
        let totalPay = entries.reduce(0) { $0 + $1.totalPay }
        return (totalSeconds / 3600.0, totalPay)
    }
    
    private func monthlyTotal() -> (hours: Double, pay: Double) {
        let calendar = Calendar.current
        let entries = job.entries.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
        let totalSeconds = entries.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
        let totalPay = entries.reduce(0) { $0 + $1.totalPay }
        return (totalSeconds / 3600.0, totalPay)
    }
}