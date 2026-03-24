import SwiftUI
import SwiftData

struct ExportView: View {
    let job: Job
    @Environment(\.dismiss) private var dismiss
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    @State private var exportDate = Date()
    @State private var exportRange: ExportRange = .monthly
    
    enum ExportRange: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    private var exportSummaryLabel: String {
        switch exportRange {
        case .weekly:
            let start = Calendar.current.startOfWeek(for: exportDate)
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
            return "\(start.format("MMM d")) - \(end.format("MMM d, yyyy"))"
        case .monthly:
            return exportDate.format("MMMM yyyy")
        case .yearly:
            return exportDate.format("yyyy")
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range Type", selection: $exportRange) {
                        ForEach(ExportRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    
                    DatePicker("Reference Date", selection: $exportDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(theme.effectiveAccent) // Updated to dynamic accent
                } header: {
                    Text("SELECT TIMEFRAME")
                        .font(.system(size: 10, weight: .black))
                }
                .listRowBackground(theme.isDarkMode ? Color("CardBackground") : Color.white)
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXPORTING FOR:")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text(exportSummaryLabel.uppercased())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    
                    ShareLink(
                        item: generateCSV(),
                        preview: SharePreview("\(job.wrappedName) Report.csv", image: Image(systemName: "doc.text.inverse"))
                    ) {
                        HStack {
                            Spacer()
                            Label("SHARE CSV REPORT", systemImage: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                            Spacer()
                        }
                        .foregroundColor(.black) // Black text for contrast on accent color
                        .padding(.vertical, 12)
                        .background(Capsule().fill(theme.effectiveAccent))
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(theme.isDarkMode ? Color("CardBackground") : Color.white)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(
                Group {
                    if theme.isDarkMode {
                        theme.backgroundColor.ignoresSafeArea()
                    } else {
                        Color(red: 0.96, green: 0.96, blue: 0.98).ignoresSafeArea() // Subtle light gray for List background
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(theme.effectiveAccent)
                }
            }
        }
    }

    // MARK: - CSV GENERATOR (Logic remains the same)
    private func generateCSV() -> String {
        var csvString = "DATE,START,END,HOURS,DAILY PAY (INC. OT)\n"
        
        let calendar = Calendar.current
        let allEntries = job.entries ?? []
        let filteredEntries: [TimeEntry]
        
        switch exportRange {
        case .weekly:
            let startOfWeek = calendar.startOfWeek(for: exportDate)
            filteredEntries = allEntries.filter { calendar.isDate($0.date, inSameWeekAs: startOfWeek) }
        case .monthly:
            filteredEntries = allEntries.filter { calendar.isDate($0.date, equalTo: exportDate, toGranularity: .month) }
        case .yearly:
            filteredEntries = allEntries.filter { calendar.isDate($0.date, equalTo: exportDate, toGranularity: .year) }
        }
        
        let entriesByWeek = Dictionary(grouping: filteredEntries) { calendar.startOfWeek(for: $0.date) }
        let sortedWeeks = entriesByWeek.keys.sorted()
        
        var reportGrandTotal = 0.0

        for weekStart in sortedWeeks {
            guard let weekEntries = entriesByWeek[weekStart]?.sorted(by: { $0.date < $1.date }) else { continue }
            
            var runningWeekHours = 0.0
            var weekTotalPay = 0.0

            for entry in weekEntries {
                let hoursBeforeThisShift = runningWeekHours
                let hoursAfterThisShift = runningWeekHours + entry.hours
                
                var dailyPay = 0.0
                
                if job.overtimeEnabled {
                    if hoursAfterThisShift <= job.overtimeThreshold {
                        dailyPay = entry.hours * entry.storedRate
                    } else if hoursBeforeThisShift >= job.overtimeThreshold {
                        dailyPay = entry.hours * job.overtimeRate
                    } else {
                        let regPart = job.overtimeThreshold - hoursBeforeThisShift
                        let otPart = hoursAfterThisShift - job.overtimeThreshold
                        dailyPay = (regPart * entry.storedRate) + (otPart * job.overtimeRate)
                    }
                } else {
                    dailyPay = entry.hours * entry.storedRate
                }
                
                runningWeekHours += entry.hours
                weekTotalPay += dailyPay
                
                let row = "\(entry.date.format("MMM d yyyy")),\(entry.startTime.format("h:mm a")),\(entry.endTime.format("h:mm a")),\(String(format: "%.2f", entry.hours)),\(String(format: "%.2f", dailyPay))\n"
                csvString.append(row)
            }
            
            reportGrandTotal += weekTotalPay
            let totalWeeklyOT = job.overtimeEnabled ? max(0, runningWeekHours - job.overtimeThreshold) : 0.0
            
            csvString.append("WEEK TOTAL,,, \(String(format: "%.2f", runningWeekHours)), \(String(format: "%.2f", weekTotalPay))\n")
            csvString.append("WEEKLY OT HOURS,,,, \(String(format: "%.2f", totalWeeklyOT))\n")
            csvString.append(",,,,\n")
        }
        
        csvString.append("REPORT GRAND TOTAL,,,, \(String(format: "%.2f", reportGrandTotal))\n")
        
        return csvString
    }
}
