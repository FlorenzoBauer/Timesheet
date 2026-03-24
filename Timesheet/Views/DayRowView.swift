import SwiftUI
import SwiftData

struct DayRowView: View {
    let dayOffset: Int
    let weekStart: Date
    let job: Job
    let previousHours: Double
    
    @Environment(\.modelContext) private var modelContext
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    @State private var showingRatePopup = false
    @State private var tempRate: String = ""
    
    @AppStorage("lastStartTime") private var lastStartTime: Double = 32400
    @AppStorage("lastEndTime") private var lastEndTime: Double = 61200
    
    var date: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)!
    }
    
    // MARK: - CUMULATIVE OT CALCULATION
    private var calculatedDayPay: (total: Double, isOT: Bool) {
        let entry = (job.entries ?? []).first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        })
        
        guard let entry = entry else { return (0, false) }
        
        let threshold = job.overtimeThreshold
        let hoursToday = entry.hours
        let rateToUse = entry.storedRate
        
        var totalPayForDay = 0.0
        var includesOT = false
        
        for i in stride(from: 0.0, to: hoursToday, by: 0.1) {
            let currentWeekCumulative = previousHours + i
            
            if job.overtimeEnabled && currentWeekCumulative >= threshold {
                totalPayForDay += (0.1 * job.overtimeRate)
                includesOT = true
            } else {
                totalPayForDay += (0.1 * rateToUse)
            }
        }
        
        return (totalPayForDay, includesOT)
    }
    
    var body: some View {
        let entry = (job.entries ?? []).first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        })
        
        HStack(spacing: 8) {
            // 1. DAY LABEL
            Text(date.format("EEE").uppercased())
                .frame(width: 40, alignment: .leading)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(entry == nil ? .secondary.opacity(0.4) : .secondary)
            
            // 2. TIME PICKERS
            timeCell(entry: entry, isStart: true)
            timeCell(entry: entry, isStart: false)
            
            Spacer()
            
            // 3. DURATION & PAY
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedDuration(entry))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Button(action: {
                    tempRate = String(format: "%.2f", entry?.storedRate ?? job.hourlyRate)
                    showingRatePopup = true
                }) {
                    HStack(spacing: 4) {
                        if calculatedDayPay.isOT {
                            Text("OT")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(theme.effectiveAccent)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            if let entry = entry, entry.storedRate != job.hourlyRate {
                                Text("$\(String(format: "%.2f", entry.storedRate))/hr")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(theme.effectiveAccent)
                            }
                            
                            Text(String(format: "$%.2f", calculatedDayPay.total))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(entry == nil ? .secondary.opacity(0.3) : (entry?.storedRate != job.hourlyRate ? theme.effectiveAccent : .primary))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(width: 90, alignment: .trailing)
        }
        .padding(.vertical, 6)
        // MARK: - OPAQUE THEME BACKGROUND
        .listRowBackground(
            ZStack {
                // The Theme Color at a low opacity
                theme.effectiveAccent.opacity(0.12)
                
                // Frosted Glass Effect
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .opacity(theme.isDarkMode ? 0.5 : 0.2)
            }
        )
        .alert("Set Rate for \(date.format("MMM d"))", isPresented: $showingRatePopup) {
            TextField("Rate", text: $tempRate).keyboardType(.decimalPad)
            Button("Save") { saveRate(newRateString: tempRate, entry: entry) }
            if entry != nil {
                Button("Reset to Default") {
                    entry?.storedRate = job.hourlyRate
                    try? modelContext.save()
                }
                .foregroundColor(.red)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    @ViewBuilder
    private func timeCell(entry: TimeEntry?, isStart: Bool) -> some View {
        if let entry = entry {
            DatePicker("", selection: timeBinding(for: entry, isStart: isStart), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .fixedSize()
                .tint(theme.effectiveAccent)
        } else {
            Button(action: { createEntry() }) {
                Text(isStart ? "START" : "END")
                    .font(.system(size: 10, weight: .black))
                    .frame(width: 60, height: 32)
                    .background(theme.effectiveAccent.opacity(0.15))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func saveRate(newRateString: String, entry: TimeEntry?) {
        guard let newRate = Double(newRateString) else { return }
        if let entry = entry {
            entry.storedRate = newRate
        } else {
            let start = Calendar.current.startOfDay(for: date).addingTimeInterval(lastStartTime)
            let end = Calendar.current.startOfDay(for: date).addingTimeInterval(lastEndTime)
            let newEntry = TimeEntry(date: date, startTime: start, endTime: end, rate: newRate, job: job)
            modelContext.insert(newEntry)
        }
        try? modelContext.save()
    }
    
    private func createEntry() {
        let start = Calendar.current.startOfDay(for: date).addingTimeInterval(lastStartTime)
        let end = Calendar.current.startOfDay(for: date).addingTimeInterval(lastEndTime)
        let newEntry = TimeEntry(date: date, startTime: start, endTime: end, rate: job.hourlyRate, job: job)
        modelContext.insert(newEntry)
        try? modelContext.save()
    }
    
    private func timeBinding(for entry: TimeEntry, isStart: Bool) -> Binding<Date> {
        Binding(
            get: { isStart ? entry.startTime : entry.endTime },
            set: { newValue in
                if isStart {
                    entry.startTime = newValue
                    lastStartTime = secondsFromMidnight(for: newValue)
                } else {
                    entry.endTime = newValue
                    lastEndTime = secondsFromMidnight(for: newValue)
                }
                try? modelContext.save()
            }
        )
    }
    
    private func formattedDuration(_ entry: TimeEntry?) -> String {
        guard let entry = entry else { return "0h 0m" }
        let diff = Int(max(0.0, entry.endTime.timeIntervalSince(entry.startTime)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func secondsFromMidnight(for date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double((comps.hour! * 3600) + (comps.minute! * 60))
    }
}

// MARK: - BLUR HELPER
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}
