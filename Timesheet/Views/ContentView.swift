import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Job.name) private var jobs: [Job]
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    @State private var selectedJob: Job?
    @State private var currentWeekStart = Calendar.current.startOfWeek(for: Date())
    
    // Navigation & Sheet States
    @State private var showingAddJob = false
    @State private var showingEditJob = false
    @State private var showingSettings = false
    @State private var showingDeleteConfirm = false
    @State private var showingMonthlySummary = false
    @State private var showingClearWeekConfirm = false
    @State private var showingExport = false
    
    // Subscription State
    @EnvironmentObject var subManager: SubscriptionManager
    @State private var showingPaywall = false

    // MARK: - OVERTIME & PAY LOGIC
    private var weeklyStats: (hours: Double, otHours: Double, pay: Double) {
        guard let job = selectedJob else { return (0, 0, 0) }
        
        let totalHours = (job.entries ?? []).filter {
            Calendar.current.isDate($0.date, inSameWeekAs: currentWeekStart)
        }.reduce(0.0) { $0 + $1.hours }
        
        let earnings = job.calculateEarnings(for: currentWeekStart)
        let otHours = job.overtimeEnabled ? max(0, totalHours - job.overtimeThreshold) : 0
        
        return (totalHours, otHours, earnings.total)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content Layer
            VStack(spacing: 0) {
                if jobs.isEmpty {
                    emptyStateView
                } else {
                    jobSwipeHeader
                    
                    if let job = selectedJob {
                        weekNavigation(for: job)
                        dayList(for: job)
                        footerSummary(for: job)
                    }
                }
            }
            .background(
                Group {
                    if theme.isDarkMode {
                        theme.backgroundColor.ignoresSafeArea()
                    } else {
                        Color(uiColor: .systemBackground).ignoresSafeArea()
                    }
                }
            )
            
            // 5. FLOATING SETTINGS BUTTON
            if !jobs.isEmpty {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.effectiveAccent)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.3 : 0.1), radius: 3, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.top, 15)
            }
        }
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        
        // MARK: - SHEETS
        .sheet(isPresented: $showingSettings) {
            // FIXED: Using environment injection
            SettingsMenuView()
                .environmentObject(subManager)
        }
        .sheet(isPresented: $showingAddJob) {
            AddJobView { newJob in selectedJob = newJob }
        }
        .sheet(isPresented: $showingEditJob) {
            if let job = selectedJob { EditJobView(job: job) }
        }
        .sheet(isPresented: $showingMonthlySummary) {
            if let job = selectedJob {
                MonthlySummaryView(job: job)
                    .presentationDetents([.fraction(0.75), .large])
            }
        }
        .sheet(isPresented: $showingExport) {
            if let job = selectedJob {
                ExportView(job: job)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            // FIXED: Using environment injection
            PaywallView()
                .environmentObject(subManager)
        }
        
        // MARK: - ALERTS
        .alert("Delete \(selectedJob?.wrappedName ?? "Job")?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteCurrentJob() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all logs for this job.")
        }
        .alert("Clear Week?", isPresented: $showingClearWeekConfirm) {
            Button("Clear All", role: .destructive) { if let job = selectedJob { clearCurrentWeek(for: job) } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all time entries for the current week.")
        }
        .onAppear {
            if selectedJob == nil { selectedJob = jobs.first }
        }
        .onChange(of: jobs) { _, newValue in
            if selectedJob == nil { selectedJob = newValue.first }
        }
    }

    // MARK: - JOB HEADER
    private var jobSwipeHeader: some View {
        TabView(selection: $selectedJob) {
            ForEach(jobs) { job in
                Menu {
                    Section("Quick Actions") {
                        Button(action: {
                            if jobs.count >= 1 && !subManager.isProUser {
                                showingPaywall = true
                            } else {
                                showingAddJob = true
                            }
                        }) {
                            Label("Add New Job", systemImage: "plus")
                        }
                        
                        Button(action: { showingEditJob = true }) {
                            Label("Job Settings", systemImage: "slider.horizontal.3")
                        }

                        Button(action: {
                            if !subManager.isProUser {
                                showingPaywall = true
                            } else {
                                showingExport = true
                            }
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    Section("Danger Zone") {
                        Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                            Label("Delete Job", systemImage: "trash")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(job.wrappedName.uppercased())
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .black))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(theme.effectiveAccent))
                }
                .tag(Optional(job))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 60)
        .padding(.top, 10)
    }

    // MARK: - WEEK NAVIGATION
    private func weekNavigation(for job: Job) -> some View {
        HStack {
            Button(action: { moveWeek(by: -7) }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
            }
            Spacer()
            Text(weekRangeString)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { moveWeek(by: 7) }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
        .tint(theme.effectiveAccent)
    }

    // MARK: - COMPACT DAY LIST
    private func dayList(for job: Job) -> some View {
        List {
            Section {
                ForEach(0..<7) { index in
                    let previousHours = (0..<index).reduce(0.0) { sum, dayOffset in
                        let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentWeekStart)!
                        let entry = (job.entries ?? []).first { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
                        return sum + (entry?.hours ?? 0)
                    }
                    
                    DayRowView(dayOffset: index, weekStart: currentWeekStart, job: job, previousHours: previousHours)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }
            } header: {
                HStack(spacing: 8) {
                    Text("DAY").frame(width: 40, alignment: .leading)
                    Text("START").frame(width: 60, alignment: .center)
                    Text("END").frame(width: 60, alignment: .center)
                    Spacer()
                    Text("PAY").frame(width: 80, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.bottom, 4)
            }
            .listRowBackground(theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 40)
    }

    // MARK: - FOOTER SUMMARY
    private func footerSummary(for job: Job) -> some View {
        VStack(spacing: 0) {
            Divider().background(theme.effectiveAccent.opacity(0.2))
            
            VStack(spacing: 12) {
                Button {
                    if subManager.isProUser {
                        showingMonthlySummary = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HOURS")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", weeklyStats.hours))
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                if weeklyStats.otHours > 0 {
                                    Text("(\(String(format: "%.1f", weeklyStats.otHours)) OT)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(theme.effectiveAccent)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                if !subManager.isProUser {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                }
                                Text("WEEK PAY")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(String(format: "$%.2f", weeklyStats.pay))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: { showingClearWeekConfirm = true }) {
                    Text("CLEAR WEEK")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
        .background(
            Group {
                if theme.isDarkMode {
                    theme.backgroundColor
                } else {
                    Color(uiColor: .systemBackground)
                }
            }
        )
    }

    // MARK: - HELPERS
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "briefcase.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.effectiveAccent.opacity(0.5))
            Text("No Jobs Found")
                .font(.system(.headline, design: .rounded))
            Button(action: { showingAddJob = true }) {
                Text("Add First Job")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(theme.effectiveAccent))
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var weekRangeString: String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart)!
        return "\(currentWeekStart.format("MMM d")) - \(end.format("MMM d"))"
    }
    
    private func moveWeek(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentWeekStart) {
            currentWeekStart = newDate
        }
    }
    
    private func deleteCurrentJob() {
        guard let jobToDelete = selectedJob else { return }
        modelContext.delete(jobToDelete)
        try? modelContext.save()
        selectedJob = jobs.first
    }
    
    private func clearCurrentWeek(for job: Job) {
        let entriesToClear = (job.entries ?? []).filter {
            Calendar.current.isDate($0.date, inSameWeekAs: currentWeekStart)
        }
        for entry in entriesToClear {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}
