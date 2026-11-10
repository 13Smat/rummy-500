# Score the cards in front of each player and decide the match in one place

## Status

Accepted

## Context

The rules sheet scores a finished hand as the points on the table minus the points still in the hand. The result can be negative, and it is added to the match total. The first player to 500 wins. If both reach 500 on the same hand, the higher total wins. If the totals are tied, the players play another hand.

Open questions 3, 6, and 8 are still open. Question 3 asks whether a low ace scores 15. Question 6 asks whether the match totals carry into the extra hand. Question 8 asks whether cards left in the hand use the same point values. A melds ticket is in progress on its own branch and does not share types with this one. `Rank.points` already holds the point table.

## Decision

`HandResult` is the boundary. It holds the cards on the table and the cards still in the hand for each seat. It does not know what a meld is. A later meld type maps into it by passing those two lists.

`HandResult.score` adds `Card.points` for the table and subtracts `Card.points` for the hand. A low ace uses the ace value, 15. Cards left in the hand use that same table. There is no second point table.

`Match` starts at zero. `record` adds one hand score. The totals, the hand scores, and the conclusion stay together. The conclusion is `playing` or `won(Seat)`. A match cannot be both. `record` on a match that already has a winner keeps the same totals.

`MatchLine` is the only place that turns two totals into that conclusion. The goal is 500. When the totals are tied at 500 or more, the conclusion stays `playing` and the next hand decides it. On that hand the higher total wins, including when a negative score drops both players below 500. If that hand is also tied, the next hand decides. The running totals carry. Open questions 3, 6, and 8 stay open in `docs/RULES.md`. The defaults above are the ones the code uses until Andy decides them.

## Consequences

A test can score a hand without a meld type. The debug build records a scripted `HandResult` and shows the hand scores and the match totals. Changing the tie rule means editing `MatchLine` only.

## Alternatives

Scoring from a meld type would couple this change to the parallel melds work. Storing a winner flag beside a playing flag would allow a winner while play continues. Deriving the winner from the totals alone would keep the match in play after a tie if the next hand dropped both players below 500. A second copy of the point values would drift from `Rank.points`.
