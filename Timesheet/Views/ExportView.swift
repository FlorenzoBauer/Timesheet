import SwiftUI
import SwiftData

struct ExportView: View {
    let job: Job
    @Environment(\.dismiss) private var dismiss
    @State private var exportDate = Date()
    @State private var exportRange: ExportRange = .monthly
    
    enum ExportRange: String, CaseIterable {
        case weekly = "This Week"
        case monthly = "This Month"
        case yearly = "This Year"
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - CONFIGURATION
                Section {
                    Picker("Export Range", selection: $exportRange) {
                        ForEach(ExportRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    DatePicker("Reference Date", selection: $exportDate, displayedComponents: .date)
                } header: {
                    Text("REPORT SETTINGS")
                } footer: {
                    Text("Select the timeframe you want to include in your spreadsheet.")
                }
                
                // MARK: - ACTION
                Section {
                    let csvData = generateCSV()
                    
                    ShareLink(
                        item: csvData,
                        preview: SharePreview(
                            "\(job.wrappedName) Export.csv",
                            image: Image(systemName: "doc.text.inverse")
                        )
                    ) {
                        HStack {
                            Spacer()
                            Label("GENERATE & SHARE CSV", systemImage: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                            Spacer()
                        }
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                    }
                }
                .listRowBackground(Color("AccentMain"))
                
                Section {
                    Text("The exported file includes: Date, Day, Start/End Times, Total Hours, Hourly Rate, and Calculated Pay (including Overtime).")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color("AccentMain"))
                }
            }
        }
    }
    
    // MARK: - CSV LOGIC
    private func generateCSV() -> String {
        // CSV Header
        var csvString = "Date,Day,Start Time,End Time,Total Hours,Hourly Rate,Total Pay\n"
        
        let calendar = Calendar.current
        let allEntries = job.entries ?? []
        
        // Filter based on selected range
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
        
        // Sort chronologically
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }
        
        for entry in sortedEntries {
            let dateStr = entry.date.format("yyyy-MM-dd")
            let dayStr = entry.date.format("EEEE")
            let startStr = entry.startTime.format("h:mm a")
            let endStr = entry.endTime.format("h:mm a")
            let hoursStr = String(format: "%.2f", entry.hours)
            let rateStr = String(format: "%.2f", entry.storedRate)
            
            // Note: We use the storedRate for that specific day to ensure accuracy 
            // even if the user changed their rate halfway through the month.
            let payStr = String(format: "%.2f", entry.hours * entry.storedRate)
            
            let line = "\(dateStr),\(dayStr),\(startStr),\(endStr),\(hoursStr),\(rateStr),\(payStr)\n"
            csvString.append(line)
        }
        
        return csvString
    }
}