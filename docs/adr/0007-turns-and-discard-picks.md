# A turn is a phase, and a picked discard has to be played at once

## Status

Accepted

## Context

The rules sheet says a turn is a draw, then any melds and layoffs, then one discard. The draw is the top of the stock, or any card in the spread discard pile together with every card above it. The chosen discard has to be melded or laid off immediately. If the hand is empty after a meld or a layoff, the player has gone out and does not discard. A hand also ends when the stock is empty and the current player does not take from the discard pile. The score is the cards on the table minus the cards still in the hand.

Open questions 1, 2, 4, and 7 are still open. This change uses the defaults named for this ticket. With an empty stock, a discard pick is still allowed when that card can be melded or laid off at once. A discard that cannot be used is refused. Discarding the last card counts as going out. "Above" means the cards discarded later than the chosen card, the ones toward the top of `DiscardPile.bottomToTop`. Those defaults are not answers written into `docs/RULES.md`.

`Deal`, `Meld`, and `HandResult` already exist. A turn has to call them. It does not deal again, it does not restate what a run or a set is, and it does not add up points.

## Decision

`HandState` is one hand in progress. `HandState.deal(seed:rotation:)` starts from `Deal.deal` on the leader's turn. The phase is one of four values.

- `awaitingDraw` means the current player has not drawn.
- `mustUsePickedCard(Card)` means that card was taken from the discard and is still in the hand.
- `mayMeldOrDiscard` means the draw is done and the player may meld, lay off, or discard.
- `handOver(Ending)` means the hand is finished. The ending is `goneOut(Seat)` or `stockExhausted`.

`drawFromStock` takes the first card of `Stock.topToBottom`. `takeDiscard` takes the chosen card and every card after it in `bottomToTop`. The cards below the chosen card stay. The take is refused with `discardCannotBeUsed` unless `Meld.layOff` accepts the chosen card on a table meld, or `Meld.layDown` accepts some group from the hand that includes it. The next meld or layoff has to use that card. Any other move is refused with `mustMeldOrLayOffPickedCard` or `pickedCardNotUsed`.

`layDown` and `layOff` call `Meld` and keep the `MeldRejection` when the group is illegal. An empty hand after either move is `goneOut` for the current seat, and no discard is required. `discard` puts one card on the top of the pile and passes the turn. Discarding the last card is also `goneOut`, and that card is on the pile, not in the score. `declineDiscardPile` is legal only while drawing with an empty stock. It ends the hand as `stockExhausted`.

Every refusal is a `TurnRejection` and returns the same value. `handResult` is nil until the hand is over. It builds a `HandResult` from `Meld.cards(playedBy:)` and the two hands. `Match.record` is still the only way the totals move.

`HandState.scriptedPlay` is one fixed hand with a buried discard pick. The debug screen steps through that trace. It is not the shuffle of `Deal.deal`.

The phase rules are also checked in `docs/statechart/RummyTurn.tla`. TLC found 24 states. The chart is `docs/statechart/chart.mmd`.

## Consequences

A test can play a hand, including a buried discard, and pass the `HandResult` to `Match` without a second copy of the point table. A debug build shows the stock count, the spread discard, both hands, the table, whose turn it is, and the score when the hand ends. Changing the empty-stock default or the last-card default means editing `HandState` and the state chart together. Open questions 1, 2, 4, and 7 stay open in `docs/RULES.md`.

## Alternatives

Two booleans, one for "has drawn" and one for "owes a card", can both be true or both be false in ways a turn never is. One phase cannot.

Treating `drawFromStock` on an empty stock as the end of the hand would score the hand on a call that was rejected. Leaving the pile is its own action.

Scoring from the turn, instead of from `HandResult`, would give the point table a second home.
