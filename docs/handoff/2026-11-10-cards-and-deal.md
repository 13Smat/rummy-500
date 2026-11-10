# Handoff

- Date. 2026-11-10.
- Branch. `cursor/cards-deck-deal-b4a0`.
- What landed. A seeded 52-card deal. A debug build lists both 13-card hands, the stock count, and the face-up discard. `DealRotation.opening` makes the computer the dealer and you the leader, and `nextHand()` swaps the dealer. That default is the only place those two answers live.
- What is not done. Melds, turns, scoring, and the computer opponent. Signing and TestFlight wait for the Apple ticket.
- How to check. `./scripts/check.sh` on Linux. On a Mac, `xcodegen generate`, then run the Rummy500 scheme in an iPhone simulator as a debug build. Enter a seed and press Deal.
- Open questions. `docs/RULES.md`, under Open questions. They are unanswered. The deal uses `DealRotation` until Andy decides who leads.
