# Deal one 52-card deck into hands, a stock, and a discard

## Status

Accepted

## Context

The rules sheet uses one 52-card deck and no jokers. Two players each receive 13 cards. The rest of the deck is the stock. The top card of that stock starts the discard pile, and every card in the pile stays visible. The sheet does not say who deals, who plays first, or the order the cards leave the deck. Open question 5 still asks Andy who leads. Melds, turns, and scoring come later, and those cards have to come from this same deck.

`SeededGenerator` is the replay source. ADR 0003 says a shuffle takes that generator and does not pin Swift's `shuffle`.

## Decision

`Card` is a rank and a suit. The point value lives on `Rank`. An ace is 15. A jack, queen, or king is 10. A card from 2 through 10 is worth its face value. The type has no joker.

`Deck` is the 52 cards, each rank and suit once. `Deck.standard` orders the suits clubs, diamonds, hearts, then spades, and the ranks ace through king inside each suit. `shuffled(using:)` runs Fisher-Yates on a copy. Each swap index comes from `SeededGenerator`, and a draw in the incomplete top of the range is replaced so the index is uniform. Index 0 is the top of the deck.

`Hand`, `Stock`, and `DiscardPile` each hold an ordered list of distinct cards. `Stock.topToBottom` starts with the next card a later turn would draw. `DiscardPile.bottomToTop` starts with the first card turned, and the last card is the top. Nothing outside the package can build one of these piles. `Deal.deal(seed:rotation:)` is the constructor for a `Deal`.

A `Deal` stores both hands, the stock, the discard, the seed, and the `DealRotation` that dealt it. The four piles are 13 cards, 13 cards, 25 cards, and 1 card. Together they are the standard deck, with no card repeated. `Deal` does not draw, meld, or score.

`DealRotation` is the only place that chooses the dealer and the leader. `DealRotation.opening` makes the computer the dealer, so you lead. `leader` is the other seat. `nextHand()` gives the deal to the other seat. Those two answers can change inside this type when Andy decides open question 5.

The deal takes cards from the top, one at a time, leader then dealer, for 13 rounds. The next card is the discard. The last 25 cards are the stock, still top to bottom.

A debug build of the app loads that deal from a seed and lists both hands, the stock count, and the discard. A release build keeps the title screen.

## Consequences

A test can replay a deal from a seed with `swift test` on Linux. The debug scene on iPhone shows the same deal. Later tickets can reuse `Card`, `Hand`, `Stock`, and `DiscardPile`, and can start a hand from `Deal`. Open question 5 stays open in `docs/RULES.md`.

## Alternatives

A hand type fixed at 13 cards would not fit going out, when a player can hold no cards. A public initializer that accepted four arrays would allow the same card in two piles. `Array.shuffle` would pin Swift's use of the generator, which ADR 0003 rules out. Writing an answer into open question 5 would decide Andy's question inside this change.
