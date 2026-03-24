import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
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
                        .font(.system(size: 10, weight: .black))
                }
                
                Section {
                    Toggle("Enable Overtime", isOn: $overtimeEnabled)
                        .tint(Color("AccentMain"))
                    
                    if overtimeEnabled {
                        HStack {
                            Text("Overtime Rate")
                            Spacer()
                            TextField("0.00", text: $overtimeRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("OVERTIME")
                        .font(.system(size: 10, weight: .black))
                } footer: {
                    Text("You can still set custom rates for specific days later on the main tracker.")
                }
            }
            .navigationTitle("New Job")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("TextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveJob()
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color("AccentMain"))
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