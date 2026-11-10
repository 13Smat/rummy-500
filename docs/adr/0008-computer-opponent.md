# The computer plays from one seat's view

## Status

Accepted

## Context

A demo match needs an opponent that can finish a game to 500. The opponent must not see the other player's cards. It must take the same actions a person takes. `HandState` stores both hands, so passing that value into the opponent would leave the hidden cards available to a later edit.

ADR 0007 defines the turn phases and the legal actions. ADR 0006 defines a meld and a layoff. The point table and the match to 500 are already in `HandResult` and `Match`. The open questions in `docs/RULES.md` stay open. This policy uses the same defaults ADR 0007 already uses for an empty stock, a discard that cannot be played, and going out on the last discard.

## Decision

`SeatView` is the only input to `ComputerOpponent.choose`. The view is built from a `HandState` for one seat. It stores that seat's hand, the discard pile from bottom to top, every meld on the table, the stock count, the phase, and the two match totals. It does not store the other hand, and it does not store the order of the stock.

`choose` returns a `ComputerPlay`. `ComputerTable` applies that play by calling `drawFromStock`, `takeDiscard`, `declineDiscardPile`, `layDown`, `layOff`, or `discard`. Those are the same methods a person uses. If one of them rejects the play, the hand stops and the failure names the play and the `TurnRejection`.

The policy is a pure function of the view. It does not draw a random number. When two cards are otherwise equal, it orders the suits clubs, diamonds, hearts, then spades, and it keeps the lower rank. The deal seed is enough to replay a hand. A match deals the first hand from the given seed and `DealRotation.opening`. Each later hand adds one to that seed and gives the deal to the other seat. Both seats use this policy.

On the draw, the computer considers every card in the discard pile. `CardUse` decides whether the chosen card can be melded or laid off at once from the hand plus the cards above it. `HandState.takeDiscard` uses that same check. The haul is worth taking when the points of the hauled cards in that play are greater than the points of the hauled cards that do not join a meld, or when every hauled card is in the play or in another meld. It takes the worth-while pick with the largest point difference. A tie takes the card closer to the top of the pile. If no pick is worth taking, it draws the stock. If the stock is also empty, it declines the pile and the hand ends.

The picked card is played on the next action. The computer lays down the highest-scoring meld that contains it. If no meld contains it, the computer lays the card off.

After the draw is finished, the computer lays down the highest-scoring new meld in its hand. It then lays off the highest-scoring card that fits a meld already on the table. It then discards one card. A card that matches another rank, or that sits next to a card of the same suit, stays in the hand. An ace next to a king counts as next to that king. The discard is the highest card that does not keep that company. If every card keeps company, the discard is the lowest of them. Discarding the last card goes out. Laying down or laying off the last card also goes out.

The match totals are on the view so a later policy can read them. This policy does not change a play because of the score.

A debug build lists a seeded match under the deal. **Next move** plays one action for the seat whose turn it is. **Auto-play** continues until `Match` names a winner. The screen shows the action, both hands, the stock count, the spread discard, the table, the hand score when the hand ends, and the match totals.

## Consequences

`swift test` can play 200 seeded hands, and it can play full matches to 500 with both seats run by this policy. An illegal move, a repeated state, or a hand that does not end fails that test with the seed. The iPhone debug screen plays the same code. A stronger opponent can replace `choose` without a second copy of the turn rules. The open questions in `docs/RULES.md` stay unanswered.

## Alternatives

Passing `HandState` into the opponent would compile, and the first version could ignore the other hand. The type would still contain those cards. `SeatView` has no field for them.

Building the next `HandState` inside the opponent would copy the turn rules. `ComputerTable` calls the methods the player calls.

Choosing among equal cards with `SeededGenerator` would add a second seed to carry through the match. Suit and rank already pick one card, so the deal seed replays the game.
