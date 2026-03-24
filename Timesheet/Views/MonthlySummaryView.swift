import SwiftUI
import SwiftData

struct MonthlySummaryView: View {
    let job: Job
    @State private var selectedMonth: Date
    @State private var showingYearlySummary = false
    @Environment(\.dismiss) private var dismiss
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared

    // MARK: - INITIALIZER
    init(job: Job, selectedMonth: Date = Date()) {
        self.job = job
        _selectedMonth = State(initialValue: selectedMonth)
    }

    var body: some View {
        ZStack {
            // MARK: - THEME BACKGROUND
            Group {
                if theme.isDarkMode {
                    theme.backgroundColor
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - HEADER NAVIGATION
                HStack {
                    Button(action: { moveMonth(by: -1) }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("MONTHLY SUMMARY")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(selectedMonth.format("MMMM yyyy").uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: { moveMonth(by: 1) }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(theme.effectiveAccent.opacity(0.1))
                .tint(theme.effectiveAccent)

                // MARK: - WEEKLY BREAKDOWN LIST
                List {
                    let weeks = weeksInMonth(for: selectedMonth)
                    
                    Section {
                        ForEach(weeks, id: \.self) { weekStart in
                            let stats = statsForWeek(weekStart)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Week of \(weekStart.format("MMM d"))")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Label("\(String(format: "%.1f", stats.hours)) hrs", systemImage: "clock")
                                        
                                        if stats.otHours > 0 {
                                            Text("\(String(format: "%.1f", stats.otHours)) OT")
                                                .font(.system(size: 10, weight: .black))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(theme.effectiveAccent)
                                                .foregroundColor(.black)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(stats.pay, format: .currency(code: "USD"))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 10)
                            // MARK: - GLASSY ROW BACKGROUND
                            .listRowBackground(
                                ZStack {
                                    theme.effectiveAccent.opacity(0.1)
                                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                                        .opacity(theme.isDarkMode ? 0.4 : 0.1)
                                }
                            )
                        }
                    }
                    
                    // MARK: - VIEW YEARLY BUTTON
                    Section {
                        Button(action: { showingYearlySummary = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "calendar.badge.clock")
                                Text("VIEW YEARLY BREAKDOWN")
                                Spacer()
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(theme.effectiveAccent)
                        }
                        .listRowBackground(theme.effectiveAccent.opacity(0.05))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                // MARK: - TOTAL FOOTER
                VStack(spacing: 12) {
                    Divider().background(theme.effectiveAccent.opacity(0.2))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL EARNINGS")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text(monthlyTotalPay(), format: .currency(code: "USD"))
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button("DONE") { dismiss() }
                            .font(.system(size: 12, weight: .black))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(theme.effectiveAccent)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 30)
                }
                .background(
                    ZStack {
                        theme.isDarkMode ? theme.backgroundColor : Color.white
                        VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
                    }
                )
            }
        }
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        .sheet(isPresented: $showingYearlySummary) {
            YearlySummaryView(job: job)
        }
    }

    // MARK: - LOGIC
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
        for day in monthRange {
            if let dateInMonth = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let weekStart = calendar.startOfWeek(for: dateInMonth)
                if !weeks.contains(weekStart) {
                    weeks.append(weekStart)
                }
            }
        }
        return weeks.sorted()
    }

    private func statsForWeek(_ weekStart: Date) -> (hours: Double, otHours: Double, pay: Double) {
        let entries = (job.entries ?? []).filter { Calendar.current.isDate($0.date, inSameWeekAs: weekStart) }
        let totalHours = entries.reduce(0.0) { $0 + $1.hours }
        
        let earnings = job.calculateEarnings(for: weekStart)
        let otHours = job.overtimeEnabled ? max(0, totalHours - job.overtimeThreshold) : 0
        
        return (totalHours, otHours, earnings.total)
    }
    
    private func monthlyTotalPay() -> Double {
        let weeks = weeksInMonth(for: selectedMonth)
        return weeks.reduce(0.0) { $0 + statsForWeek($1).pay }
    }
}
