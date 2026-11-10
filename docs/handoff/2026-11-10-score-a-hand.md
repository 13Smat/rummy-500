# Handoff

- Date. 2026-11-10.
- Branch and pull request. `cursor/score-hand-and-match-b1b3`.
- What landed. A finished hand scores the cards on the table minus the cards left in the hand. Laid-off cards count for the player who played them, because those cards are in that player's table list. The match adds each hand score, and a negative score lowers the total. The first total to 500 wins. If both reach 500 on the same hand, the higher total wins. If the totals are tied, the match stays in play and the next hand's higher total wins. That decision lives in `MatchLine`. A debug build has a Sample score section. Press Score next hand.
- What is not done. Melds, turns, and the computer opponent. A later screen can display these totals. Signing and TestFlight wait for the Apple ticket.
- How to check. `./scripts/check.sh` on Linux. On a Mac, `xcodegen generate`, then run the Rummy500 scheme in an iPhone simulator as a debug build. Scroll to Sample score and press Score next hand.
- Open questions. `docs/RULES.md`, under Open questions. They are unanswered. Scoring uses the defaults noted on questions 3, 6, and 8 until Andy decides them.
