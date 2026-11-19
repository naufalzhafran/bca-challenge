import Foundation

public enum Money {
    public static let dailyLimit: Decimal = 50_000_000
    public static let minimumAmount: Decimal = 10_000

    /// Two decimals, half-even (R11).
    public static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .bankers)
        return output
    }
}

public enum Masker {
    /// 1234567890 becomes ******7890 (R12).
    public static func account(_ accountNo: String) -> String {
        guard accountNo.count > 4 else { return "****" }
        return String(repeating: "*", count: accountNo.count - 4) + accountNo.suffix(4)
    }
}
