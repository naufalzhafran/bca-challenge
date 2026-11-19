# Lab Bank mobile core (Swift): bug hunt

A vendor ported the Lab Bank transfer rules to Swift, for the mobile team and a new transfer service. It is a Swift package with 20 unit tests, and the vendor says all of them pass.

You do not need a Mac and you do not run this code. You review it with your AI tools. **Start with [`CHALLENGE.md`](CHALLENGE.md).**

| Folder / file | What it is |
|---|---|
| `CHALLENGE.md` | Tickets, rules, scoring |
| `SUBMISSION.md` | Your answer sheet. Fill it and hand it in |
| `docs/PRD.md` | Product rules (R1 to R14). The same PRD as the web app; the screens and the HTTP codes in it are for the web app, the rules are the same |
| `Sources/LabBankCore/` | The code under review |
| `Tests/LabBankCoreTests/` | The 20 passing tests |

## Code map

| File | What it does |
|---|---|
| `Models.swift` | `Account`, `Session`, `Transfer`, `TransferRequest`, error codes |
| `Money.swift` | Limits, rounding, account masking |
| `BankClock.swift` | Clock for tests, WIB calendar, cut-off |
| `ReferenceNumber.swift` | Reference numbers such as `TRF20261119A1B2C3` |
| `Stores.swift` | In-memory account and transfer stores, lookup of accounts at other banks |
| `TransferService.swift` | Inquiry, transfer, history |
| `AccountService.swift` | Account summary and daily limit usage |
| `SettlementJob.swift` | Morning job that sends the `PENDING` transfers |
| `SeedData.swift` | Demo accounts |

## Demo data

| User | Accounts | Balance |
|---|---|---|
| `andi` | `1234567890` (savings), `1234567891` (current) | Rp75.000.000, Rp5.250.000 |
| `budi` | `2345678901` | Rp12.500.000 |
| `citra` | `3456789012` | Rp3.000.000 |
| (no mobile user yet) | `4567890123`, Gita Permata | Rp48.200.000 |

Other banks: BRI `002` / `0011223344`, Mandiri `008` / `1370012345678`, BNI `009` / `0456789123`. Lab Bank's own code is `999`.

All data is made up. This is a training sample, not production code.
