# Changelog

## Unreleased

- Told agents to run /setup-pstack first, before any other pstack skill.
- Added `Meld` in `RummyEngine`. A set of 3 or 4 and a suited run of 3 or more can be laid down. Ace-low and ace-high runs are legal. Ace through king of one suit is an ace-low run. King, ace, 2, a mixed suit, and five of a kind are rejected.
- A layoff can extend a set or a run, including a meld played by the other seat. Each card keeps the seat that played it.
- A debug deal lists the largest legal melds in each hand.
- Added hand scoring and a match total to 500 in `RummyEngine`. A debug build can score a scripted hand and show the totals.
- Added cards, a 52-card deck, and a seeded two-player deal in `RummyEngine`.
- A debug build can open that deal by seed and show both hands, the stock count, and the discard.

## 0.1.0

- Added the Rummy 500 rules sheet, including the open questions.
- Added `RummyEngine`, a pure Swift package with a seeded generator and the names of the rule areas that are not built yet.
- Added the SwiftUI iPhone shell, generated from `project.yml`.
- Added pull-request checks for the engine on Linux and the app on an iPhone simulator.
- Vendored pstack 0.15.36 so cloud agents load the same skills.
