# Changelog

## Unreleased

- The table is a wood surface with a green felt. The computer's cards fan face down along the top. Your cards fan across the bottom. The stock shows how many cards are left, and it shares a tray with the spread discard. Diamonds are blue, clubs are green, hearts are red, and spades are black. One Sort button switches suit order and rank order. The gear and the trophy do nothing yet.
- Drag the stock into your hand to draw, drag a discard into your hand to take it, and drag one card onto the discard pile to discard. Drag a card to a new place in your hand. Lay down, Discard, and Move left and Move right are gone. Sort by suit, sort by rank, X, and Play remain. The stock and the discard glow for the move you need, and a layoff plays the card the engine can take first.
- Drag cards into the play area to build a meld. Play stays visible and turns on when those cards are a legal meld or a layoff onto one meld. X sends them back to your hand. VoiceOver can move a card in or out without a drag.
- The TestFlight archive is unsigned. Export signs it for App Store distribution, so the upload does not need a registered device.
- The TestFlight archive command does not pass a signing identity. A distribution identity on that command conflicted with the app target and with the RummyEngine package.
- On the table you can draw, take a discard, lay down, lay off, and discard. A refusal explains the move in plain words and leaves the hand as it was. The computer plays its turn one move at a time. When the hand ends, deal the next one and the score stays.
- A TestFlight workflow uploads a signed Release build. The marketing version is 0.1.0. The build number is the Actions run number. The app answers export compliance as no. The icon is still a placeholder.
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
