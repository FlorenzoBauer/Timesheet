import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    var onCreate: (Job) -> Void
    
    @State private var name = ""
    @State private var rate = ""
    @State private var overtimeEnabled = false
    @State private var overtimeRate = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Job Name (e.g. Starbucks)", text: $name)
                    
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("0.00", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("BASIC INFO")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                }
                .listRowBackground(theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                
                Section {
                    Toggle("Enable Overtime", isOn: $overtimeEnabled)
                        .tint(theme.effectiveAccent) // Consistent Accent
                    
                    if overtimeEnabled {
                        HStack {
                            Text("Overtime Rate")
                            Spacer()
                            TextField("0.00", text: $overtimeRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(theme.effectiveAccent) // Consistent Accent
                        }
                    }
                } header: {
                    Text("OVERTIME")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                } footer: {
                    Text("You can still set custom rates for specific days later on the main tracker.")
                }
                .listRowBackground(theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            }
            .navigationTitle("New Job")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .scrollContentBackground(.hidden)
            .background(
                // Matching the dynamic background logic from Settings
                Group {
                    if theme.isDarkMode {
                        theme.backgroundColor.opacity(0.9)
                    } else {
                        Color.white.opacity(0.8)
                    }
                }
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.effectiveAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveJob()
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(theme.effectiveAccent)
                    .disabled(name.isEmpty || rate.isEmpty)
                }
            }
        }
    }
    
    private func saveJob() {
        let baseRate = Double(rate.filter { "0123456789.".contains($0) }) ?? 0.0
        let otRate = Double(overtimeRate.filter { "0123456789.".contains($0) }) ?? 0.0
        
        let newJob = Job(name: name, hourlyRate: baseRate)
        newJob.overtimeEnabled = overtimeEnabled
        newJob.overtimeRate = otRate
        
        modelContext.insert(newJob)
        try? modelContext.save()
        
        onCreate(newJob)
        dismiss()
    }
}
