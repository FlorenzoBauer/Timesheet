import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    let job: Job
    let weekStart: Date
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared
    
    var body: some View {
        let weekEntries = (job.entries ?? []).filter {
            Calendar.current.isDate($0.date, inSameWeekAs: weekStart)
        }
        
        // Using the job's calculation logic for consistency
        let earnings = job.calculateEarnings(for: weekStart)
        let totalHours = weekEntries.reduce(0.0) { $0 + $1.hours }
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL HOURS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f", totalHours))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("WEEKLY PAY")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(earnings.total, format: .currency(code: "USD"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(theme.effectiveAccent) // Updated to dynamic accent
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(
            Group {
                if theme.isDarkMode {
                    theme.backgroundColor
                } else {
                    Color.white
                }
            }
        )
    }
}
