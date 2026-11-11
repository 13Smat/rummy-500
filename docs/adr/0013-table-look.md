# Draw the table like a wood card table

## Status

Accepted

## Context

The phone table already shows a hand, a face-down computer hand, a spread discard, melds, scores, and the turn. ADR 0009 drew that as a flat green screen with a gap between your cards, red and black suits, and two sort buttons. Andy wants the same table to feel like the reference card table: wood around a felt, a fan of cards, one Sort button, and a tray for the stock and the discard. The art, the logos, and the card backs in that reference stay out. The open questions in `docs/RULES.md` stay unanswered. The engine does not change.

## Decision

The screen draws its own wood, felt, card back, and two face tokens with SwiftUI shapes. The gear and the trophy are buttons that do nothing. The computer's cards fan face down along the top and are clipped at the top. A pill under that fan shows the computer's match score. Your score is a glowing pill labeled YOU, with Sort on the same row. X and Play stay on that row. Play stays off until the staged cards are one legal meld or one layoff.

Your cards fan across the bottom and overlap. Each card's center stays uncovered, so a tap or a drag still hits that card on an iPhone SE width. A hand longer than the screen scrolls. The visible edge is at least half a card plus a small margin. The stock and the discard share a lighter tray at the lower right of the felt. The stock shows the count on the card back. The discard stays spread at a 44-point stride and scrolls inside the tray.

Diamonds are blue, clubs are green, hearts are red, and spades are black. Each card still shows the suit symbol and the suit letter. Sort calls the same suit order and rank order as before, and it switches between them. The drag routes, the taps, the VoiceOver actions, and the identifiers for the hand, the stock, the discard, the play area, X, and Play stay.

## Consequences

The on-screen test requires the opponent fan, the stock count, the discard tray, Sort, X, and Play. The screenshot test saves a picture of each table state. A thirteen-card fan fits a 375-point width without covering a card's center. The gear and the trophy are still placeholders. The open questions in `docs/RULES.md` stay unanswered.

## Alternatives

Keeping a gap between hand cards would make hits obvious and would not match the fan. Copying the reference art would put someone else's pictures in the app. Collapsing the discard to one card would hide the deeper cards Rummy 500 lets you take. Two sort buttons would keep the old tests and would not match the one Sort pill.
