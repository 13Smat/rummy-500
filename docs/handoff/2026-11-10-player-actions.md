# Handoff

- Date. 2026-11-10.
- Branch and pull request. `cursor/player-actions-e78a`. The pull request link is filled in when the branch is pushed.
- What landed. The table plays a hand. `TableSession` calls `HandState` for a draw, a discard pick, a meld, a layoff, and a discard. A refusal keeps the hand and shows one plain sentence. By suit, By rank, Move left, and Move right reorder your cards on screen. After you discard, the screen steps `ComputerTable.step` with a short pause and shows what the computer did. When the hand ends, Deal the next hand keeps the match score. The choice is `docs/adr/0010-player-actions.md`.
- What is not done. Full match chrome, VoiceOver beyond the labels on the controls, and a drag that reorders cards. Signing and TestFlight stay with the Apple ticket.
- How to check. `./scripts/check.sh` on Linux. On a Mac, `./scripts/ios-ci.sh` runs the app tests and the UI test that plays seed 0 through one round. Open the table, draw, discard, and watch the computer. Long discard shows the card you have to play.
- Open questions. `docs/RULES.md`, under Open questions. They are unanswered.
