# Status

Updated 2026-11-10.

## In this branch

- The official demo rules are in `docs/RULES.md`. Open questions at the bottom of that file are unanswered. Scoring uses the defaults noted on questions 3, 6, and 8.
- `Packages/RummyEngine` builds on Linux. It deals a 52-card deck from a seed into two hands of 13, a stock of 25, and one face-up discard. `DealRotation` holds the proposed dealer and leader until open question 5 is decided.
- A finished hand scores the cards on each player's table minus the cards still in that player's hand. The hand score is added to a match total. `MatchLine` is the only place that names a winner at 500, including a tie.
- The iPhone app shows the name Rummy 500 and links the engine. A debug build lists a seeded deal under that title and can score a scripted hand. The Xcode project is generated from `project.yml`.
- Pull requests run the engine tests on Ubuntu and build the app for an iPhone simulator on macOS.
- pstack 0.15.36 is vendored at commit `08547969e1dffaa6457ea65141cc62c1d9a2eef1`.

## Later tickets

Melds, turns, and the computer opponent are not in this branch. Signing, a real bundle id, and TestFlight upload wait for the Apple ticket.

## Product source

`docs/RULES.md` is the source of the rules. Decisions about the repo are in `docs/adr/`.
