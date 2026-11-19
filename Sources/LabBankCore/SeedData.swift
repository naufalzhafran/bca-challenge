import Foundation

/// Demo data. Made up, same as the Lab Bank web app.
public enum SeedData {
    public static let accounts: [Account] = [
        Account(accountNo: "1234567890", ownerId: "andi", ownerName: "Andi Wijaya", accountType: "SAVINGS", balance: 75_000_000),
        Account(accountNo: "1234567891", ownerId: "andi", ownerName: "Andi Wijaya", accountType: "CURRENT", balance: 5_250_000),
        Account(accountNo: "2345678901", ownerId: "budi", ownerName: "Budi Santoso", accountType: "SAVINGS", balance: 12_500_000),
        Account(accountNo: "3456789012", ownerId: "citra", ownerName: "Citra Lestari", accountType: "SAVINGS", balance: 3_000_000),
        // moved from the old core system, owner has no mobile user yet
        Account(accountNo: "4567890123", ownerId: nil, ownerName: "Gita Permata", accountType: "SAVINGS", balance: 48_200_000),
    ]

    public static func accountStore() -> InMemoryAccountStore {
        InMemoryAccountStore(accounts)
    }
}
