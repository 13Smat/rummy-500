# Handoff

- Date. 2026-11-11.
- Branch and pull request. `cursor/drag-the-table-0846`. The pull request removes the action-row buttons and plays the turn by drag.
- What landed. Draw, take, discard, and hand order go through `CardDragRoute.drop` and `TableSession.effect`. Sort by suit, sort by rank, X, and Play stay. The stock and the discard glow for the move you need. The turn chip says whose turn it is. An empty stock is a tap on the stock. A finished hand is a tap on that chip. `PlayArea.layingOff` commits the first card `HandState.layOff` accepts and scans again, so 5 then 6 and jack then 10 both extend a 7-8-9 on seed 8029. VoiceOver can draw, take a discard, discard, stage, and move left or right. The choice is `docs/adr/0012-play-area.md`.
- What is not done. An owed card that fits a meld only after a bridge card is laid off first still fails. `HandState.layOff` requires the owed card on the first call. Open questions in `docs/RULES.md` stay unanswered.
- How to check. `./scripts/check.sh` runs the engine tests. The iPhone simulator job runs the drag UI tests and the unit tests, including the hand-index test and the seed 8029 layoff.
- Open questions. They stay in `docs/RULES.md`. This change does not answer them.
