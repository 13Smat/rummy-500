# Rummy 500 demo rules

This is the official rule sheet for the two-player demo. Play is standard 500 Rum as described by Bicycle, at [500 Rum](https://bicyclecards.com/how-to-play/500-rum), except where this sheet names a difference. The point table below is the usual 500 Rum scale. Bicycle does not print one.

## The pack and the deal

Use one 52-card deck. There are no jokers.

The game is two players. Deal 13 cards to each player. The rest of the deck is the stock. Turn the top card of the stock to start the discard pile. Spread the discard pile so every card in it stays visible.

The 7-card deal is for three or more players. This demo does not use it.

## Melds

A meld is one of these:

- A set of 3 or 4 cards of the same rank.
- A run of 3 or more cards in the same suit.

An ace may be high, as in queen, king, ace. An ace may be low, as in ace, 2, 3. A run may not turn the corner. King, ace, 2 is not a run.

## A turn

On your turn, do one of these:

- Draw the top card of the stock.
- Take a card from the discard pile, together with every card above that card.

The card you chose from the discard pile must be melded or laid off immediately. You may meld the extra cards on that same turn, or keep them in your hand.

After you draw, you may lay down new melds. You may also lay off cards on any meld already on the table, including a meld that belongs to the other player. Cards you lay off stay in front of you, and they count for your score.

End the turn by discarding one card. If you have no cards left after melding or laying off, you have gone out, and you do not discard.

## End of a hand

A hand ends when a player goes out. A hand also ends when the stock is empty and the current player does not take from the discard pile.

## Score

Score the hand as the points on the table in front of you, minus the points still in your hand. The result can be negative. Add it to your match total.

Point values:

- An ace is 15 points.
- A king, queen, or jack is 10 points.
- A card from 2 through 10 is worth its face value.

A match is the first player to 500 points. If both players reach 500 on the same hand, the higher score wins. If the scores are tied, play another hand.

## Left out of this demo

These are not part of the demo unless this sheet is changed later.

- Jokers.
- Gin rummy.
- Counting a low ace as 1 point.
- The 7-card deal.

The sheet states no bonus for going out.

## Open questions

These are for Andy. The engine work should not pick an answer quietly.

1. **Empty stock.** The sheet says a hand ends when the stock is empty and the current player does not take from the discard pile. It does not say whether that player may still take from the discard and leave the opponent to face an empty stock. It also does not say the hand ends the moment the stock becomes empty, before anyone chooses.
2. **A discard card that cannot be used.** The chosen discard card must be melded or laid off immediately. The sheet does not say the take is refused when no legal meld or layoff exists. It does not say what happens when the stock is also empty and no discard card can be used.
3. **A low ace's score.** An ace may be played low, in ace, 2, 3. The point table says an ace is 15. The sheet also says that counting a low ace as 1 is out of this demo. Please confirm that a low ace still scores 15. Until that is decided, the engine scores every ace as 15, including an ace played in ace, 2, 3.
4. **Going out on a discard.** You go out when you have no cards left after melding or laying off, and then you do not discard. The sheet does not say whether discarding your last card also counts as going out.
5. **Who leads.** The sheet does not say who plays first after the deal, or who deals the next hand.
6. **A tie at 500 or more.** If the match scores are tied, the players play another hand. The sheet does not say whether those match totals carry into the extra hand. Until that is decided, the engine keeps the running totals. A tie at 500 or more stays in play. The next hand gives the win to the higher total, even when both totals fall below 500. A further tie stays in play.
7. **Cards above the one you take.** "Above" is read here as the cards discarded later than the card you chose, the ones sitting on top of it in the pile. Please confirm that reading.
8. **Points left in the hand.** The sheet subtracts "the cards still in your hand" from the table points. Please confirm that those cards use the same point values as cards on the table. Until that is decided, the engine subtracts the same point values for cards left in the hand.
