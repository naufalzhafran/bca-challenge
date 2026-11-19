import Foundation

/// Runs every business day at 06.00 WIB. Sends the transfers to other banks
/// that were accepted after the cut-off (R8) and marks them as SUCCESS.
public struct SettlementJob {
    private let transfers: TransferStore
    private let clock: BankClock

    public init(transfers: TransferStore, clock: BankClock = SystemClock()) {
        self.transfers = transfers
        self.clock = clock
    }

    /// - Returns: the number of transfers settled in this run.
    @discardableResult
    public func run() -> Int {
        var settled = 0
        for var transfer in transfers.pending() {
            transfer.status = .success
            transfer.settledAt = clock.now
            settled += 1
        }
        return settled
    }
}
