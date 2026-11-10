# Status

Updated 2026-11-10.

## In this branch

- The official demo rules are in `docs/RULES.md`. Open questions at the bottom of that file are unanswered. Scoring uses the defaults noted on questions 3, 6, and 8.
- `Packages/RummyEngine` builds on Linux. It deals a 52-card deck from a seed into two hands of 13, a stock of 25, and one face-up discard. `DealRotation` holds the proposed dealer and leader until open question 5 is decided.
- A meld is a set of 3 or 4, or a suited run of 3 or more. Ace-low and ace-high are legal. Ace through king of one suit is an ace-low run. King, ace, 2 is not. Each card on a meld remembers the seat that played it. A debug build lists the largest legal melds in each dealt hand.
- A finished hand scores the cards on each player's table minus the cards still in that player's hand. The hand score is added to a match total. `MatchLine` is the only place that names a winner at 500, including a tie.
- A turn draws the top of the stock, or a discard plus every card above it. The chosen discard has to be melded or laid off before any other move. The hand ends when a player goes out, including by discarding the last card, or when the stock is empty and that player does not take a usable discard. `HandState.handResult` feeds `HandResult`. The phase check is `docs/statechart/RummyTurn.tla`.
- The computer plays both seats from a `SeatView`. The view has its own hand, the spread discard, the melds, the stock count, and the match totals. It does not have the other hand. Every play goes through `HandState`. The policy is in `docs/adr/0008-computer-opponent.md`.
- The iPhone table reads a `HandState` and the match totals. Your hand is face up. The computer's hand is a face-down count. The discard is spread. Each meld card keeps the seat that played it. A menu loads a fresh deal, a mid-hand, and a long discard pile. From that table you draw, take a discard, lay down, lay off, discard, and deal the next hand. The computer plays through `ComputerTable.step`. The choice is `docs/adr/0009-table-screen.md` and `docs/adr/0011-player-actions.md`. A debug build still lists a seeded deal, a sample score, a scripted hand, and a computer match behind a Debug button. The Xcode project is generated from `project.yml`.
- Pull requests run the engine tests on Ubuntu and build the app for an iPhone simulator on macOS. The simulator job also archives an unsigned Release build.
- A separate workflow uploads a signed Release build to TestFlight. The steps are in `docs/TESTFLIGHT.md`. The icon is still a flat green placeholder.
- pstack 0.15.36 is vendored at commit `08547969e1dffaa6457ea65141cc62c1d9a2eef1`.

## Later tickets

The real app icon is a later ticket. A stronger opponent can replace the policy in `ComputerOpponent.choose` later.

## Product source

`docs/RULES.md` is the source of the rules. Decisions about the repo are in `docs/adr/`.
