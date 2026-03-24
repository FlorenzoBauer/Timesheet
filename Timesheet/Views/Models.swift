import Foundation
import SwiftData

@Model
final class Job {
    var name: String
    var hourlyRate: Double
    
    init(name: String, hourlyRate: Double = 0.0) {
        self.name = name
        self.hourlyRate = hourlyRate
    }
}

@Model
final class TimeEntry {
    var date: Date
    var startTime: Date
    var endTime: Date
    var jobId: PersistentIdentifier
    
    init(date: Date, startTime: Date, endTime: Date, jobId: PersistentIdentifier) {
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.jobId = jobId
    }
}
