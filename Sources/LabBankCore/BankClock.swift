import Foundation

/// Source of the current time, so tests can use a fixed time.
public protocol BankClock {
    var now: Date { get }
}

public struct SystemClock: BankClock {
    public init() {}
    public var now: Date { Date() }
}

public struct FixedClock: BankClock {
    public var now: Date
    public init(_ now: Date) {
        self.now = now
    }
}

/// Bank time is WIB (Asia/Jakarta) for every customer.
public enum BankCalendar {
    public static let timeZone = TimeZone(identifier: "Asia/Jakarta")!

    public static let wib: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()

    /// Cut-off for transfers to other banks: 15.00 WIB (R8).
    public static let cutOffHour = 15

    public static func isAfterCutOff(_ date: Date) -> Bool {
        wib.component(.hour, from: date) >= cutOffHour
    }

    /// Builds a WIB date. For seed data and tests.
    public static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return wib.date(from: parts)!
    }
}
