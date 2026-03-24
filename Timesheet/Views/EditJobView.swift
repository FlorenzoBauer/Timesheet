import SwiftUI
import SwiftData

struct EditJobView: View {
    @Bindable var job: Job
    @Environment(\.dismiss) var dismiss
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - IDENTITY SECTION
                Section {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(theme.effectiveAccent)
                        
                        TextField("Job Name", text: Binding(
                            get: { job.name ?? "" },
                            set: { job.name = $0 }
                        ))
                        .font(.headline)
                    }
                } header: {
                    Text("JOB DETAILS")
                        .font(.system(size: 10, weight: .black))
                }
                
                // MARK: - PAY RATES SECTION
                Section {
                    HStack {
                        Text("Base Rate")
                        Spacer()
                        TextField("Hourly", value: $job.hourlyRate, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .fontWeight(.bold)
                    }
                    
                    Toggle("Enable Overtime", isOn: $job.overtimeEnabled)
                        .tint(theme.effectiveAccent)
                    
                    if job.overtimeEnabled {
                        HStack {
                            Text("Overtime Rate")
                            Spacer()
                            TextField("Rate", value: $job.overtimeRate, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Overtime Threshold")
                            Spacer()
                            TextField("Hours", value: $job.overtimeThreshold, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("hrs")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("PAY RATES")
                        .font(.system(size: 10, weight: .black))
                } footer: {
                    Text("Changing the base rate only affects new shifts. Existing logs keep their original rates.")
                        .font(.system(size: 10))
                        .padding(.top, 5)
                }
                
                // MARK: - ACTIONS SECTION
                Section {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Cancel Changes")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Job Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(
                Group {
                    if theme.isDarkMode {
                        theme.backgroundColor.ignoresSafeArea()
                    } else {
                        Color.white.ignoresSafeArea()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(theme.effectiveAccent)
                }
            }
        }
    }
    
    private func saveChanges() {
        do {
            try job.modelContext?.save()
            dismiss()
        } catch {
            print("Error saving job changes: \(error.localizedDescription)")
            dismiss()
        }
    }
}
