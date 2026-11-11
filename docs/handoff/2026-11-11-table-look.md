# Handoff

- Date. 2026-11-11.
- Branch and pull request. `cursor/table-look-9d1d`. The pull request restyles the phone table.
- What landed. The table is wood around a green felt. The computer's hand fans face down at the top. Your hand fans across the bottom, with each card's center left uncovered. The stock and the spread discard share a tray. Diamonds are blue, clubs are green, hearts are red, and spades are black. Sort toggles suit and rank. The gear and the trophy do nothing. Drag, tap, VoiceOver, X, and Play stay. The choice is `docs/adr/0013-table-look.md`.
- What is not done. The gear and the trophy have no screens. The bottom tab bar from the reference is out of scope. An owed card that fits a meld only after a bridge card is laid off first still fails. Open questions in `docs/RULES.md` stay unanswered.
- How to check. `./scripts/check.sh` runs the engine tests. The iPhone simulator job runs the drag UI tests and saves a picture of each table state. The on-screen test requires the opponent fan, the stock count, the discard tray, Sort, X, and Play. The wood is a few gradient bands. The drag test waits until the turn chip says your turn, because the computer can play more than once before it hands the turn back.
- Open questions. They stay in `docs/RULES.md`. This change does not answer them.
