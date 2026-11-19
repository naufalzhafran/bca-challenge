import Foundation

/// Fund transfer (docs/PRD.md). An actor, so two calls never run at the same time.
public actor TransferService {
    private let accounts: AccountStore
    private let transfers: TransferStore
    private let directory: BankDirectory
    private let clock: BankClock

    public init(accounts: AccountStore, transfers: TransferStore, directory: BankDirectory,
                clock: BankClock = SystemClock()) {
        self.accounts = accounts
        self.transfers = transfers
        self.directory = directory
        self.clock = clock
    }

    /// Name of the beneficiary, shown before the customer confirms (R7).
    public func inquiry(bankCode: String, accountNo: String) async throws -> Beneficiary {
        guard let bankName = Bank.names[bankCode] else {
            throw TransferError.bankNotSupported
        }
        if bankCode == Bank.own {
            guard let account = accounts.find(accountNo) else {
                throw TransferError.accountNotFound
            }
            return Beneficiary(bankCode: bankCode, bankName: bankName,
                               accountNo: account.accountNo, accountName: account.ownerName)
        }
        return try await directory.lookup(bankCode: bankCode, accountNo: accountNo)
    }

    public func transfer(_ request: TransferRequest, session: Session) async throws -> Transfer {
        // 1. basic checks
        guard let userId = session.userId else {
            throw TransferError.forbidden
        }
        guard request.amount > 0 else {
            throw TransferError.invalidRequest("Amount must be more than 0")
        }
        if let note = request.note, note.count > 100 {
            throw TransferError.invalidRequest("Note is longer than 100 characters")
        }
        let amount = Money.rounded(request.amount)
        guard Bank.names[request.toBankCode] != nil else {
            throw TransferError.bankNotSupported
        }
        guard amount >= Money.minimumAmount else {
            throw TransferError.belowMinimum
        }
        let isOwnBank = request.toBankCode == Bank.own
        if isOwnBank && request.fromAccount == request.toAccount {
            throw TransferError.sameAccount
        }

        // 2. source account
        guard var source = accounts.find(request.fromAccount) else {
            throw TransferError.accountNotFound
        }
        guard source.ownerId == userId else {
            throw TransferError.forbidden
        }

        // 3. same request sent again -> return the first result
        if let key = request.idempotencyKey,
           let first = transfers.find(userId: userId, idempotencyKey: key) {
            return first
        }

        // 4. daily limit
        let now = clock.now
        let usedToday = DailyLimit.used(fromAccount: source.accountNo, at: now, in: transfers)
        guard usedToday + amount <= Money.dailyLimit else {
            throw TransferError.limitExceeded
        }

        // 5. balance
        guard source.balance > amount else {
            throw TransferError.insufficientFunds
        }

        // 6. target account
        let beneficiary = try await inquiry(bankCode: request.toBankCode, accountNo: request.toAccount)

        // 7. status: other banks after cut-off are sent next business day
        let status: TransferStatus = !isOwnBank && BankCalendar.isAfterCutOff(now) ? .pending : .success

        // 8. debit and credit
        source.balance -= amount
        accounts.save(source)
        if isOwnBank, var target = accounts.find(request.toAccount) {
            target.balance += amount
            accounts.save(target)
        }

        // 9. save the transfer
        let transfer = Transfer(
            referenceNo: ReferenceNumber.make(at: now),
            idempotencyKey: request.idempotencyKey,
            userId: userId,
            fromAccount: source.accountNo,
            toBankCode: request.toBankCode,
            toAccount: request.toAccount,
            toName: beneficiary.accountName,
            amount: amount,
            note: request.note,
            status: status,
            createdAt: now,
            settledAt: status == .success ? now : nil,
            balanceAfter: source.balance)
        transfers.save(transfer)
        return transfer
    }

    public func history(session: Session) -> [Transfer] {
        guard let userId = session.userId else { return [] }
        return transfers.history(userId: userId)
    }
}
