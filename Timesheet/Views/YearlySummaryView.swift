import SwiftUI
import SwiftData

struct YearlySummaryView: View {
    let job: Job
    @State private var selectedYear = Date()
    @Environment(\.dismiss) private var dismiss
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    // For navigating back to a specific month if the user taps a row
    @State private var monthToOpen: Date?
    @State private var showingMonthlyDetail = false

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
                // MARK: - YEAR NAVIGATION (HEADER)
                HStack {
                    Button(action: { moveYear(by: -1) }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("ANNUAL REPORT")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(selectedYear.format("yyyy"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: { moveYear(by: 1) }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(theme.effectiveAccent.opacity(0.1))
                .tint(theme.effectiveAccent)

                // MARK: - MONTHLY LIST
                List {
                    ForEach(1...12, id: \.self) { month in
                        let monthDate = dateForMonth(month)
                        let stats = statsForMonth(monthDate)
                        
                        Button(action: {
                            monthToOpen = monthDate
                            showingMonthlyDetail = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(monthDate.format("MMMM").uppercased())
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("\(String(format: "%.1f", stats.hours)) HOURS TOTAL")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(stats.pay, format: .currency(code: "USD"))
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(theme.effectiveAccent)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        // MARK: - GLASSY ROW BACKGROUND
                        .listRowBackground(
                            ZStack {
                                theme.effectiveAccent.opacity(0.1)
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                                    .opacity(theme.isDarkMode ? 0.4 : 0.15)
                            }
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                // MARK: - YEARLY FOOTER
                VStack(spacing: 12) {
                    Divider().background(theme.effectiveAccent.opacity(0.2))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selectedYear.format("yyyy")) TOTAL")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text(yearlyTotalPay(), format: .currency(code: "USD"))
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button("CLOSE") { dismiss() }
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
        .sheet(isPresented: $showingMonthlyDetail) {
            if let date = monthToOpen {
                MonthlySummaryView(job: job, selectedMonth: date)
            }
        }
    }

    // MARK: - LOGIC
    private func moveYear(by value: Int) {
        if let newYear = Calendar.current.date(byAdding: .year, value: value, to: selectedYear) {
            selectedYear = newYear
        }
    }
    
    private func dateForMonth(_ month: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: selectedYear)
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private func statsForMonth(_ monthDate: Date) -> (hours: Double, pay: Double) {
        let weeks = weeksInMonth(for: monthDate)
        var totalHours = 0.0
        var totalPay = 0.0
        
        for weekStart in weeks {
            let earnings = job.calculateEarnings(for: weekStart)
            totalPay += earnings.total
            
            let weekEntries = (job.entries ?? []).filter {
                Calendar.current.isDate($0.date, inSameWeekAs: weekStart)
            }
            totalHours += weekEntries.reduce(0.0) { $0 + $1.hours }
        }
        
        return (totalHours, totalPay)
    }

    private func yearlyTotalPay() -> Double {
        (1...12).reduce(0.0) { sum, month in
            sum + statsForMonth(dateForMonth(month)).pay
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
        return weeks
    }
}
