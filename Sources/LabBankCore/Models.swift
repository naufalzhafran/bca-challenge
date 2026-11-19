import Foundation

/// A Lab Bank account. Balances are in rupiah.
public struct Account: Equatable {
    public let accountNo: String
    /// User ID of the owner. `nil` for accounts moved from the old core system
    /// that are not linked to a mobile user yet.
    public var ownerId: String?
    public let ownerName: String
    public let accountType: String
    public var balance: Decimal

    public init(accountNo: String, ownerId: String?, ownerName: String, accountType: String, balance: Decimal) {
        self.accountNo = accountNo
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.accountType = accountType
        self.balance = balance
    }
}

/// The caller of a service. `userId` is `nil` until login is complete.
public struct Session: Equatable {
    public let userId: String?

    public init(userId: String?) {
        self.userId = userId
    }

    public static let guest = Session(userId: nil)
}

public enum TransferStatus: String, Equatable {
    case success = "SUCCESS"
    case pending = "PENDING"
}

public struct TransferRequest: Equatable {
    public var fromAccount: String
    public var toBankCode: String
    public var toAccount: String
    public var amount: Decimal
    public var note: String?
    public var idempotencyKey: String?

    public init(fromAccount: String, toBankCode: String = Bank.own, toAccount: String, amount: Decimal,
                note: String? = nil, idempotencyKey: String? = nil) {
        self.fromAccount = fromAccount
        self.toBankCode = toBankCode
        self.toAccount = toAccount
        self.amount = amount
        self.note = note
        self.idempotencyKey = idempotencyKey
    }
}

public struct Transfer: Equatable {
    public let referenceNo: String
    public let idempotencyKey: String?
    public let userId: String
    public let fromAccount: String
    public let toBankCode: String
    public let toAccount: String
    public let toName: String
    public let amount: Decimal
    public let note: String?
    public var status: TransferStatus
    public let createdAt: Date
    public var settledAt: Date?
    /// Balance of the source account right after the transfer (R14).
    public let balanceAfter: Decimal
}

public struct AccountSummary: Equatable {
    public let accountNo: String
    public let maskedNo: String
    public let ownerName: String
    public let balance: Decimal
    public let dailyLimit: Decimal
    public let dailyLimitUsed: Decimal
    public let dailyLimitRemaining: Decimal
}

public struct Beneficiary: Equatable {
    public let bankCode: String
    public let bankName: String
    public let accountNo: String
    public let accountName: String

    public init(bankCode: String, bankName: String, accountNo: String, accountName: String) {
        self.bankCode = bankCode
        self.bankName = bankName
        self.accountNo = accountNo
        self.accountName = accountName
    }
}

public enum Bank {
    public static let own = "999"
    public static let names: [String: String] = [
        "999": "Lab Bank",
        "002": "BRI",
        "008": "Bank Mandiri",
        "009": "BNI",
    ]
}

/// Errors with the codes from docs/PRD.md.
public enum TransferError: Error, Equatable {
    case invalidRequest(String)
    case forbidden
    case accountNotFound
    case belowMinimum
    case limitExceeded
    case insufficientFunds
    case sameAccount
    case bankNotSupported

    public var errorCode: String {
        switch self {
        case .invalidRequest: return "INVALID_REQUEST"
        case .forbidden: return "FORBIDDEN"
        case .accountNotFound: return "ACCOUNT_NOT_FOUND"
        case .belowMinimum: return "BELOW_MINIMUM"
        case .limitExceeded: return "LIMIT_EXCEEDED"
        case .insufficientFunds: return "INSUFFICIENT_FUNDS"
        case .sameAccount: return "SAME_ACCOUNT"
        case .bankNotSupported: return "BANK_NOT_SUPPORTED"
        }
    }
}
