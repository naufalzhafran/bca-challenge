import Foundation

/// Reference numbers look like TRF20261119A1B2C3: TRF + date in WIB + 6 characters.
public enum ReferenceNumber {
    private static let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = BankCalendar.wib
        formatter.timeZone = BankCalendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "YYYYMMdd"
        return formatter
    }()

    public static func make(at date: Date) -> String {
        var generator = SystemRandomNumberGenerator()
        return make(at: date, using: &generator)
    }

    static func make<G: RandomNumberGenerator>(at date: Date, using generator: inout G) -> String {
        let suffix = (0..<6).map { _ in characters.randomElement(using: &generator)! }
        return "TRF" + dateFormatter.string(from: date) + String(suffix)
    }
}
