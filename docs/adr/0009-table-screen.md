# Show the phone table as a reading of HandState

## Status

Accepted

## Context

The player needs a portrait iPhone table before the game can take taps. The table has to show a 13-card hand, a longer hand after a discard pick, a face-down computer hand, the stock, every card in the discard, both players' melds, the match scores, and whose turn it is. `HandState` already holds the hand. `Match` already holds the totals. The open questions in `docs/RULES.md` stay unanswered.

`Hand`, `Stock`, and `DiscardPile` cannot be built outside the engine. A preset has to start from `HandState.deal(seed:)` and play public moves, or it would invent a second way to build a hand.

## Decision

`TableScene` is the reading the screen uses. It keeps your cards, sorted by suit in deck order and then by rank with the ace low. It keeps the computer's hand as a count. It keeps the stock as a count. It keeps every discard, bottom to top. It keeps each meld card with the seat from `Meld.played`. The turn line is "Your turn" or "Computer's turn" while the hand is in progress, and "Hand over" when the phase says the hand has ended. The line under it names the phase in plain words.

The match totals come from `Match`. They are not the unfinished hand. A fresh deal shows 0 and 0. The other two presets show totals from earlier finished hands, using `Match.record` and `HandResult`.

Three presets cover the screen. Fresh deal is seed 0, still in the deal. Mid-hand plays legal draws, melds, a discard, and layoffs until the computer is to meld or discard. Long discard plays legal draws and discards, then one deep discard pick, so your hand is longer than 13 and the cards left in the pile are still spread.

The view draws that reading. It does not decide whether a meld is legal, and it does not draw, meld, or discard. Card faces show the rank, a suit symbol, and a suit letter. Hearts and diamonds are red. Clubs and spades are black. The symbol and the letter still differ when the color is the same. Face-down cards are a flat back. The table is a flat color. Cards are at least 44 points wide and tall. The hand leaves a gap between cards. The discard overlaps only past that 44-point stride, and the row scrolls.

A debug build opens the existing deal, score, and turn lists from a Debug button.

## Consequences

A test can check counts, the face-down computer hand, meld seats, and the turn line without a snapshot. The same three presets open in the app. A later ticket can attach taps to these cards. It should not grow a second hand type.

## Alternatives

Drawing `HandState` straight from the view would show the computer's cards, because those cards are on the value. The screen would have to remember to hide them in every place.

A new engine fixture that accepted four piles would let a preset skip the rules. `HandState.deal` plus the public moves is the one way to reach a hand.

Showing the largest groups in a dealt hand as table melds would put cards on the table that are still in the hand. A fresh deal has no table melds.
