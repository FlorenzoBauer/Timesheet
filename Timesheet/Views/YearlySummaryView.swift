import SwiftUI
import SwiftData

struct YearlySummaryView: View {
    let job: Job
    let year: Int
    
    var totalHours: Double {
        job.entries
            .filter { Calendar.current.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.hours }
    }
    
    var totalEarnings: Double {
        totalHours * job.hourlyRate
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(String(year)) TOTAL")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f hrs", totalHours))
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("ESTIMATED PAY")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(totalEarnings.formatted(.currency(code: "USD")))
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.75, blue: 0.78).opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}