import Foundation

extension Calendar {
    /// Finds the first day of the week (usually Sunday or Monday depending on locale)
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
    
    /// Checks if a date falls within the same week as another date
    func isDate(_ date: Date, inSameWeekAs weekDate: Date) -> Bool {
        return self.isDate(date, equalTo: weekDate, toGranularity: .weekOfYear)
    }
}

extension Date {
    /// A static formatter to save memory and improve scrolling performance
    private static let sharedFormatter = DateFormatter()

    /// Formats a date into a string (e.g., "EEE" for Mon, "MMM d" for Mar 19)
    func format(_ format: String) -> String {
        Self.sharedFormatter.dateFormat = format
        return Self.sharedFormatter.string(from: self)
    }
    
    /// Helper to get just the time components for storing in AppStorage
    var timeAsSeconds: Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        return Double((comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60)
    }
}
