import XCTest
@testable import LabBankCore

final class TransferServiceTests: XCTestCase {
    private let andiSavings = "1234567890"
    private let budiSavings = "2345678901"
    private let citraSavings = "3456789012"
    private let andi = Session(userId: "andi")
    private let citra = Session(userId: "citra")

    private var accounts: InMemoryAccountStore!
    private var transfers: InMemoryTransferStore!

    override func setUp() {
        accounts = SeedData.accountStore()
        transfers = InMemoryTransferStore()
    }

    private func service(hour: Int = 10, minute: Int = 0) -> TransferService {
        TransferService(accounts: accounts, transfers: transfers, directory: StubBankDirectory(),
                        clock: FixedClock(BankCalendar.date(2026, 11, 20, hour, minute)))
    }

    private func assertThrows(_ expected: TransferError, file: StaticString = #filePath, line: UInt = #line,
                              _ body: () async throws -> Void) async {
        do {
            try await body()
            XCTFail("Expected \(expected.errorCode)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? TransferError, expected, file: file, line: line)
        }
    }

    func test_T1_transferInsideLabBankDebitsSourceAndCreditsTarget_R9() async throws {
        let result = try await service().transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 500_000), session: andi)

        XCTAssertEqual(accounts.find(andiSavings)?.balance, 74_500_000)
        XCTAssertEqual(accounts.find(budiSavings)?.balance, 13_000_000)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.toName, "Budi Santoso")
        XCTAssertEqual(result.balanceAfter, 74_500_000)
    }

    func test_T2_amountOfZeroIsRejected_R3() async {
        await assertThrows(.invalidRequest("Amount must be more than 0")) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 0), session: andi)
        }
    }

    func test_T3_amountJustBelowMinimumIsRejected_R3() async {
        await assertThrows(.belowMinimum) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 9_999), session: andi)
        }
    }

    func test_T4_amountAtMinimumIsAccepted_R3() async throws {
        let result = try await service().transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 10_000), session: andi)

        XCTAssertEqual(result.amount, 10_000)
        XCTAssertEqual(accounts.find(andiSavings)?.balance, 74_990_000)
    }

    func test_T5_oneAmountJustAboveDailyLimitIsRejected_R4() async {
        await assertThrows(.limitExceeded) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 50_000_001), session: andi)
        }
        XCTAssertEqual(accounts.find(andiSavings)?.balance, 75_000_000)
    }

    func test_T6_amountOverDailyLimitWithEarlierTransfersIsRejected_R4() async throws {
        _ = try await service(hour: 8).transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 45_000_000), session: andi)

        await assertThrows(.limitExceeded) {
            _ = try await service(hour: 10).transfer(
                TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 6_000_000), session: andi)
        }
        XCTAssertEqual(accounts.find(andiSavings)?.balance, 30_000_000)
    }

    func test_T7_amountAboveBalanceIsRejected_R5() async {
        await assertThrows(.insufficientFunds) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: citraSavings, toAccount: budiSavings, amount: 3_000_001), session: citra)
        }
        XCTAssertEqual(accounts.find(citraSavings)?.balance, 3_000_000)
    }

    func test_T8_sourceAndTargetAreTheSameAccount_R6() async {
        await assertThrows(.sameAccount) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: andiSavings, toAccount: andiSavings, amount: 20_000), session: andi)
        }
    }

    func test_T9_sourceAccountOfAnotherUserIsRejected_R2() async {
        await assertThrows(.forbidden) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: budiSavings, toAccount: andiSavings, amount: 20_000), session: andi)
        }
        XCTAssertEqual(accounts.find(budiSavings)?.balance, 12_500_000)
    }

    func test_T10_transferToOtherBankJustBeforeCutOffIsSuccess_R8() async throws {
        let result = try await service(hour: 14, minute: 59).transfer(
            TransferRequest(fromAccount: andiSavings, toBankCode: "002", toAccount: "0011223344", amount: 25_000),
            session: andi)

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.toName, "Dewi Anggraini")
    }

    func test_T11_transferToOtherBankAtCutOffIsPending_R8() async throws {
        let result = try await service(hour: 15).transfer(
            TransferRequest(fromAccount: andiSavings, toBankCode: "002", toAccount: "0011223344", amount: 25_000),
            session: andi)

        XCTAssertEqual(result.status, .pending)
        XCTAssertNil(result.settledAt)
        XCTAssertEqual(accounts.find(andiSavings)?.balance, 74_975_000)
    }

    func test_T12_sameIdempotencyKeySentAgainReturnsFirstResult_R10() async throws {
        let request = TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 500_000,
                                      idempotencyKey: "key-1")
        let first = try await service().transfer(request, session: andi)
        let again = try await service().transfer(request, session: andi)

        XCTAssertEqual(again.referenceNo, first.referenceNo)
        XCTAssertEqual(accounts.find(andiSavings)?.balance, 74_500_000)
        XCTAssertEqual(transfers.history(userId: "andi").count, 1)
    }

    func test_T13_amountIsRoundedHalfEvenToTwoDecimals_R11() async throws {
        let result = try await service().transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: Decimal(string: "10000.125")!),
            session: andi)

        XCTAssertEqual(result.amount, Decimal(string: "10000.12")!)
    }

    func test_T14_referenceNumberStartsWithTheWibDate_R14() async throws {
        let result = try await service(hour: 0, minute: 30).transfer(
            TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 20_000), session: andi)

        XCTAssertTrue(result.referenceNo.hasPrefix("TRF20261120"))
        XCTAssertEqual(result.referenceNo.count, 17)
    }

    func test_T15_guestCannotTransfer_R1() async {
        await assertThrows(.forbidden) {
            _ = try await service().transfer(
                TransferRequest(fromAccount: andiSavings, toAccount: budiSavings, amount: 20_000), session: .guest)
        }
    }
}
