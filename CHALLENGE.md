# Bug hunt: Lab Bank mobile core (Swift)

The vendor delivered this Swift package last month. All 20 unit tests pass. Still, tickets came in.

Most of you do not write Swift, and you cannot run this project. That is the point: find each cause by reading the code with your AI tools, and prove it by reasoning.

- **Time:** 45 minutes. You work alone.
- **Tools:** Kiro and any model. No Mac, no Swift compiler, no online Swift playground.
- **Hand in:** `SUBMISSION.md`.
- **Prizes:** the three highest scores. If two scores are equal, the earlier hand-in wins.

## Tickets

### SW-1 · "I cannot empty my account" (10 points)

Citra has Rp3.000.000. She sends all of it to Budi at Lab Bank and gets `INSUFFICIENT_FUNDS`. Sending Rp2.990.000 works.

### SW-2 · "Transfers are missing from the 2025 year-end report" (15 points)

Finance: the transfers made on 28 to 31 December 2025 have reference numbers that start with `TRF2026`. Transfers made on 27 December 2025 are fine. In November everything looks right.

### SW-3 · "My limit does not reset at midnight" (15 points)

Since the transfer service moved to a cloud server last week, customers who use their full daily limit in the evening still get `LIMIT_EXCEEDED` after 00.00 WIB. Around 07.00 WIB it works again. The server clock is set to UTC. The developers cannot reproduce it on their laptops in Jakarta.

### SW-4 · "My transfer is still PENDING" (15 points)

Budi sent money to BRI on Tuesday at 16.00 WIB. On Thursday it is still `PENDING`. The settlement job ran on both mornings, and its log says "settled 1 transfer" each time.

### SW-5 · "Two transfers, one debit" (20 points)

Citra had Rp3.000.000. She sent Rp2.000.000 to BRI `0011223344` from her phone and her tablet at the same moment. Both devices show a receipt with `SUCCESS`, her history has two transfers, and her balance is Rp1.000.000. The vendor says this cannot happen, because `TransferService` is an actor.

### SW-6 · "The app is not consistent" (10 points)

At 15.05 WIB Andi sent money to Budi at Lab Bank: it arrived at once. In the same minute he sent money to BNI `0456789123`: the status is `PENDING`. He wants both to behave the same way.

### SW-7 · No ticket yet (15 points)

A security reviewer left one note before going on leave: "Someone who is not logged in can read a balance." Nothing else. Find it.

## What to hand in for each ticket

Fill one block in `SUBMISSION.md` per ticket. Not every ticket is a real bug.

| Part | What we look for | Share of the ticket's points |
|---|---|---|
| Verdict and root cause | Bug or not a bug. File and line, why it goes wrong, and the PRD rule it breaks | 40% |
| Trace | One concrete example followed through the code by hand: the input, the values at each step, the wrong result. This replaces running the code | 30% |
| Fix | The changed lines, written out. Small, and it must not break another rule | 20% |
| Prompt | The one prompt that helped most. It gives context (ticket, rule, files) and asks for evidence, not only for a fix | 10% |

For a ticket that is not a bug, the verdict with its evidence is the whole answer. A "fix" for it costs 5 points.

## Rules

- You cannot run the code, so you must check the model's answer another way: follow the example yourself, ask for the exact Swift behavior with a source, or ask a second model and compare.
- "The AI said so" is not evidence. Write down what you checked.
- An answer that names the wrong line earns no root-cause points, even if the fix happens to work.
- The 20 tests pass. They are part of the puzzle: look at what they do not check.

## A way to work

1. **Context first.** Give the model `docs/PRD.md` and the code map in `README.md`. Tell it you are a Java developer who does not know Swift.
2. **Ask for causes, not for a fix.** Paste the ticket. Ask for possible causes with file and line, and what in the ticket supports each one.
3. **Ask how Swift differs.** Many of these bugs sit where Swift behaves differently from Java. Ask: "what would a Java developer wrongly assume about this code?"
4. **Trace one example.** Make the model walk through the ticket's own numbers, line by line. Check the arithmetic yourself.
5. **Cross-check.** Ask a second model to attack the first answer. Keep the cause that survives.
