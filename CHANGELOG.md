# Changelog

## Unreleased

- The iPhone table shows your hand face up, the computer's hand face down, the stock, every discard, both players' melds, the match scores, and whose turn it is. A menu loads a fresh deal, a mid-hand with layoffs, or a long discard pile. Debug lists stay behind a Debug button.
- The computer plays a legal Rummy 500 hand from its own cards, the spread discard, the table, the stock count, and the match totals. It can take a deeper discard when that card melds at once and the extra cards are worth it. It lays down, lays off, and goes out. A debug build steps through a seeded match with Next move and Auto-play.
- A turn in `RummyEngine` is a draw, then melds and layoffs, then one discard. The draw is the top of the stock, or a discard plus every card above it. The chosen discard has to be melded or laid off before any other move. Going out, including by discarding the last card, ends the hand. An empty stock ends the hand when the player does not take a usable discard. The score still comes from `HandResult`.
- A debug build steps through a scripted hand and shows the stock, the spread discard, both hands, the table, whose turn it is, and the score.
- Agents run /setup-pstack only when `.cursor/rules/pstack-models.mdc` is missing. A rerun waits until Andy asks for a new budget or a new model.
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
