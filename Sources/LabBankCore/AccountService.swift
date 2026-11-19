import Foundation

public struct AccountService {
    private let accounts: AccountStore
    private let transfers: TransferStore
    private let clock: BankClock

    public init(accounts: AccountStore, transfers: TransferStore, clock: BankClock = SystemClock()) {
        self.accounts = accounts
        self.transfers = transfers
        self.clock = clock
    }

    /// Balance and today's limit usage of one of the caller's accounts (R2, R4).
    public func summary(accountNo: String, session: Session) throws -> AccountSummary {
        guard let account = accounts.find(accountNo) else {
            throw TransferError.accountNotFound
        }
        guard account.ownerId == session.userId else {
            throw TransferError.forbidden
        }
        let used = DailyLimit.used(fromAccount: accountNo, at: clock.now, in: transfers)
        return AccountSummary(
            accountNo: account.accountNo,
            maskedNo: Masker.account(account.accountNo),
            ownerName: account.ownerName,
            balance: account.balance,
            dailyLimit: Money.dailyLimit,
            dailyLimitUsed: used,
            dailyLimitRemaining: max(Money.dailyLimit - used, 0))
    }
}

/// Daily limit per source account, counted from 00.00 WIB (R4).
enum DailyLimit {
    static func used(fromAccount: String, at now: Date, in transfers: TransferStore) -> Decimal {
        let startOfDay = Calendar.current.startOfDay(for: now)
        return transfers.sum(fromAccount: fromAccount, since: startOfDay)
    }
}
