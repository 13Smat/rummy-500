# Keep a meld legal and remember who played each card

## Status

Accepted

## Context

The rules sheet allows a set of 3 or 4 cards of one rank, and a run of 3 or more cards of one suit. An ace may be low, as in ace, 2, 3, or high, as in queen, king, ace. A run may not turn the corner. King, ace, 2 is not a run. The demo uses one deck, so five of a kind cannot occur. There are no jokers.

A player may lay a card on any meld already on the table, including a meld that belongs to the other player. The card stays credited to the player who played it. Scoring, in a later ticket, reads the cards each player has on the table and the cards still in each hand. It does not need turn order.

`Card`, `Hand`, `Deal`, and `Seat` already exist. This change uses them and does not redefine them. The open questions in `docs/RULES.md` stay unanswered. This change does not decide when a hand ends, whether a discard that cannot be melded is refused, or how a low ace scores. An ace is worth 15 because `Rank.points` already says so. That is the point table, not a new answer to open question 3.

## Decision

`Meld` is created only by `layDown(_:playedBy:)` and `layOff(_:playedBy:)`. Both return `Result<Meld, MeldRejection>`. The initializer is private, so an illegal group cannot be built.

`PlayedCard` is one card and the `Seat` that played it. `Meld.played` is that list in table order. `cards(playedBy:)` returns one seat's cards from one meld. A later scoring ticket can flatten several melds with `flatMap` and can read a hand from `Hand.cards`.

A set is stored clubs, diamonds, hearts, then spades. A run is stored from its low end to its high end. An ace-low run starts with the ace. An ace-high run ends with the ace.

`MeldRejection` names the failure.

- `needsThreeCards` means the group has fewer than 3 cards.
- `fiveOfAKind` means 5 or more cards of one rank.
- `duplicateCard` means the same card appears twice.
- `mixedSuit` means the cards are not one rank and not one suit.
- `wrapsAround` means the ranks turn the corner, including king, ace, 2, and a run that uses the ace at both ends.
- `notInSequence` means a same-suit group skips a rank.
- `doesNotFit` means a layoff does not continue the meld. A wrap, a mixed suit, a duplicate, and five of a kind keep their own reasons.

`largestGroups(in:playedBy:)` returns the largest set of each rank and the longest run of each suit. A shorter run inside a longer one is omitted. Ace-low and ace-high can both appear when they share the single ace. The debug deal lists those groups under each hand. Seed 0 shows no meld for you and the 5, 6, 7, and 8 of clubs for the computer.

Layoff checks the combined cards with the same rule as a new meld. The new card takes the seat passed to `layOff`. The cards already in the meld keep their seats.

## Consequences

A test can reject king, ace, 2, a mixed suit, and five of a kind without a turn machine. Scoring can ignore meld shape and read `cards(playedBy:)`. The debug screen can show that a dealt hand has no legal meld.

## Alternatives

Separate set and run types would split the owner list. Scoring would have to handle both shapes. One `played` list is the same walk for a set and a run.

A table or turn type would have to answer the open questions about an empty stock and a discard that cannot be used. Those questions stay in the rules sheet.

Listing every legal subset would turn one long run into many lines on the debug screen. The screen shows the longest group. `layDown` still accepts a shorter run from the same cards.
