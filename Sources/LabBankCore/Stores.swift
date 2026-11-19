import Foundation

public protocol AccountStore: AnyObject {
    func find(_ accountNo: String) -> Account?
    func save(_ account: Account)
}

public protocol TransferStore: AnyObject {
    func save(_ transfer: Transfer)
    func find(userId: String, idempotencyKey: String) -> Transfer?
    func history(userId: String) -> [Transfer]
    func pending() -> [Transfer]
    /// Sum of the transfers from this account created at or after `since`.
    func sum(fromAccount: String, since: Date) -> Decimal
}

/// Looks up an account at another bank. This is a network call.
public protocol BankDirectory {
    func lookup(bankCode: String, accountNo: String) async throws -> Beneficiary
}

public final class InMemoryAccountStore: AccountStore, @unchecked Sendable {
    private var accounts: [String: Account] = [:]

    public init(_ accounts: [Account] = []) {
        for account in accounts {
            self.accounts[account.accountNo] = account
        }
    }

    public func find(_ accountNo: String) -> Account? {
        accounts[accountNo]
    }

    public func save(_ account: Account) {
        accounts[account.accountNo] = account
    }
}

public final class InMemoryTransferStore: TransferStore, @unchecked Sendable {
    private var transfers: [Transfer] = []

    public init() {}

    /// Adds the transfer, or replaces the one with the same reference number.
    public func save(_ transfer: Transfer) {
        if let index = transfers.firstIndex(where: { $0.referenceNo == transfer.referenceNo }) {
            transfers[index] = transfer
        } else {
            transfers.append(transfer)
        }
    }

    public func find(userId: String, idempotencyKey: String) -> Transfer? {
        transfers.first { $0.userId == userId && $0.idempotencyKey == idempotencyKey }
    }

    public func history(userId: String) -> [Transfer] {
        transfers.filter { $0.userId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    public func pending() -> [Transfer] {
        transfers.filter { $0.status == .pending }
    }

    public func sum(fromAccount: String, since: Date) -> Decimal {
        transfers
            .filter { $0.fromAccount == fromAccount && $0.createdAt >= since }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
}

/// Fixed list of accounts at other banks, for the demo and the tests.
public struct StubBankDirectory: BankDirectory, Sendable {
    public init() {}

    public func lookup(bankCode: String, accountNo: String) async throws -> Beneficiary {
        let known = [
            "002/0011223344": "Dewi Anggraini",
            "008/1370012345678": "Eko Prasetyo",
            "009/0456789123": "Fajar Nugroho",
        ]
        guard let bankName = Bank.names[bankCode], let name = known["\(bankCode)/\(accountNo)"] else {
            throw TransferError.accountNotFound
        }
        return Beneficiary(bankCode: bankCode, bankName: bankName, accountNo: accountNo, accountName: name)
    }
}
