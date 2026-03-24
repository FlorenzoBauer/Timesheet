import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    let job: Job
    let weekStart: Date
    
    var body: some View {
        let weekEntries = (job.entries ?? []).filter {
            Calendar.current.isDate($0.date, inSameWeekAs: weekStart)
        }
        
        let totalPay = weekEntries.reduce(0.0) { $0 + $1.totalPay }
        let totalHours = weekEntries.reduce(0.0) { $0 + $1.hours }
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL HOURS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
                
                Text(String(format: "%.1f", totalHours))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("WEEKLY PAY")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
                
                Text(totalPay, format: .currency(code: "USD"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(Color("AccentMain")) // Using the theme's pop color
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
        .background(Color("AppBackground"))
    }
}