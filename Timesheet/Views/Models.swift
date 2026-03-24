import Foundation
import SwiftData

// MARK: - Job Model
@Model
final class Job {
    // CloudKit likes optional strings or clear defaults
    var name: String?
    var hourlyRate: Double = 0.0
    
    // Overtime Settings
    var overtimeEnabled: Bool = false
    var overtimeRate: Double = 0.0
    var overtimeThreshold: Double = 40.0
    
    // Relationship: CloudKit requires the inverse to be explicitly defined
    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.job)
    var entries: [TimeEntry]? = []
    
    init(name: String? = "New Job",
         hourlyRate: Double = 0.0,
         overtimeEnabled: Bool = false,
         overtimeRate: Double = 0.0,
         overtimeThreshold: Double = 40.0) {
        
        self.name = name
        self.hourlyRate = hourlyRate
        self.overtimeEnabled = overtimeEnabled
        self.overtimeThreshold = overtimeThreshold
        
        // Default OT to 1.5x if not specified
        if overtimeRate == 0.0 {
            self.overtimeRate = hourlyRate * 1.5
        } else {
            self.overtimeRate = overtimeRate
        }
    }

    // Safely unwrap name for the UI
    var wrappedName: String {
        name ?? "Unnamed Job"
    }

    /// Calculates a detailed breakdown for a specific week
    func calculateEarnings(for weekStart: Date) -> (regular: Double, overtime: Double, total: Double) {
        let calendar = Calendar.current
        let weekEntries = (entries ?? []).filter { calendar.isDate($0.date, inSameWeekAs: weekStart) }
        
        let totalHours = weekEntries.reduce(0.0) { $0 + $1.hours }
        
        if overtimeEnabled && totalHours > overtimeThreshold {
            let regularHours = overtimeThreshold
            let otHours = totalHours - overtimeThreshold
            
            let regPay = regularHours * hourlyRate
            let otPay = otHours * overtimeRate
            return (regPay, otPay, regPay + otPay)
        } else {
            let totalPay = totalHours * hourlyRate
            return (totalPay, 0.0, totalPay)
        }
    }
}

// MARK: - TimeEntry Model
@Model
final class TimeEntry {
    var date: Date = Date()
    var startTime: Date = Date()
    var endTime: Date = Date()
    var storedRate: Double = 0.0
    var job: Job?

    init(date: Date = Date(),
         startTime: Date = Date(),
         endTime: Date = Date(),
         rate: Double = 0.0,
         job: Job? = nil) {
        
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.storedRate = rate
        self.job = job
    }
    
    /// Returns duration in decimal hours (e.g., 8.5)
    var hours: Double {
        let duration = endTime.timeIntervalSince(startTime)
        return max(0.0, duration / 3600.0)
    }
    
    /// Returns the pay for this specific entry based on the rate stored at the time of entry
    var totalPay: Double {
        return hours * storedRate
    }
}
