# Status

Updated 2026-11-10.

## In this branch

- The official demo rules are in `docs/RULES.md`. Open questions at the bottom of that file are unanswered.
- `Packages/RummyEngine` builds on Linux. It exposes `Seed`, `SeededGenerator`, and `RuleArea`.
- The iPhone app shows the name Rummy 500 and links the engine. The Xcode project is generated from `project.yml`.
- Pull requests run the engine tests on Ubuntu and build the app for an iPhone simulator on macOS.
- pstack 0.15.36 is vendored at commit `08547969e1dffaa6457ea65141cc62c1d9a2eef1`.

## Later tickets

Cards, the deal, melds, turns, and scoring are not in this branch. The computer opponent is not in this branch. Signing, a real bundle id, and TestFlight upload wait for the Apple ticket.

## Product source

`docs/RULES.md` is the source of the rules. Decisions about the repo are in `docs/adr/`.
