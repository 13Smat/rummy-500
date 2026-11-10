# Handoff

- Date: 2026-11-10.
- Branch: `cursor/computer-opponent-27b2`.
- What landed. The computer plays a legal hand from a `SeatView` and can finish a match to 500. A debug build steps that match with Next move and Auto-play. The policy is `docs/adr/0008-computer-opponent.md`.
- What is not done. A stronger opponent, and the table layout, are later tickets. Signing and TestFlight stay on the Apple ticket.
- How to check. `swift test --package-path Packages/RummyEngine` and `./scripts/check.sh`. On a Mac, generate the project and run the Rummy500 tests. The debug screen is under the scripted hand.
- Open questions. They stay in `docs/RULES.md`. This change does not answer them.
