import XCTest
@testable import LabBankCore

final class AccountAndSettlementTests: XCTestCase {
    private let andiSavings = "1234567890"
    private let budiSavings = "2345678901"
    private let andi = Session(userId: "andi")

    private var accounts: InMemoryAccountStore!
    private var transfers: InMemoryTransferStore!

    override func setUp() {
        accounts = SeedData.accountStore()
        transfers = InMemoryTransferStore()
    }

    private func clock(_ day: Int, _ hour: Int) -> FixedClock {
        FixedClock(BankCalendar.date(2026, 11, day, hour))
    }

    func test_T16_summaryShowsBalanceAndDailyLimitLeft_R4() async throws {
        let transferService = TransferService(accounts: accounts, transfers: transfers,
                                              directory: StubBankDirectory(), clock: clock(20, 9))
        _ = try await transferService.transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 12_000_000), session: andi)

        let summary = try AccountService(accounts: accounts, transfers: transfers, clock: clock(20, 10))
            .summary(accountNo: andiSavings, session: andi)

        XCTAssertEqual(summary.balance, 63_000_000)
        XCTAssertEqual(summary.dailyLimitUsed, 12_000_000)
        XCTAssertEqual(summary.dailyLimitRemaining, 38_000_000)
        XCTAssertEqual(summary.maskedNo, "******7890")
    }

    func test_T17_summaryOfAnotherUsersAccountIsRejected_R2() {
        let service = AccountService(accounts: accounts, transfers: transfers, clock: clock(20, 10))

        XCTAssertThrowsError(try service.summary(accountNo: budiSavings, session: andi)) { error in
            XCTAssertEqual(error as? TransferError, .forbidden)
        }
    }

    func test_T18_guestCannotReadACustomersAccount_R1() {
        let service = AccountService(accounts: accounts, transfers: transfers, clock: clock(20, 10))

        XCTAssertThrowsError(try service.summary(accountNo: andiSavings, session: .guest)) { error in
            XCTAssertEqual(error as? TransferError, .forbidden)
        }
    }

    func test_T19_settlementJobSettlesPendingTransfers_R8() async throws {
        let transferService = TransferService(accounts: accounts, transfers: transfers,
                                              directory: StubBankDirectory(), clock: clock(19, 16))
        _ = try await transferService.transfer(
            TransferRequest(fromAccount: andiSavings, toBankCode: "002", toAccount: "0011223344", amount: 25_000),
            session: andi)
        _ = try await transferService.transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 25_000), session: andi)

        let settled = SettlementJob(transfers: transfers, clock: clock(20, 6)).run()

        XCTAssertEqual(settled, 1)
    }

    func test_T20_dailyLimitStartsAgainOnTheNextDay_R4() async throws {
        let yesterday = TransferService(accounts: accounts, transfers: transfers,
                                        directory: StubBankDirectory(), clock: clock(19, 13))
        _ = try await yesterday.transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 50_000_000), session: andi)

        let today = TransferService(accounts: accounts, transfers: transfers,
                                    directory: StubBankDirectory(), clock: clock(20, 10))
        let result = try await today.transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 20_000_000), session: andi)

        XCTAssertEqual(result.status, .success)
    }
}
