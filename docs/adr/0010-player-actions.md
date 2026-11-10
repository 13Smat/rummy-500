# The table plays through one session

## Status

Accepted

## Context

The iPhone table reads a `HandState` and does not draw, meld, or discard. ADR 0007 is the turn. ADR 0008 is the computer, and `ComputerTable.step` plays one move. ADR 0009 says a later ticket can attach taps to these cards and should not grow a second hand type. The open questions in `docs/RULES.md` stay open.

## Decision

`TableSession` holds the hand, the match, the order of your cards, and the cards you have selected. Draw, take a discard, lay down, lay off, discard, and leave the pile call the same `HandState` methods the computer calls. If you are not the seat to play, the session does not call the engine. A refusal keeps the hand and shows one sentence from `TurnRejection` or `MeldRejection`.

The picked card stays marked until you meld it or lay it off. The line above the table says to play that card before you do anything else.

By suit, By rank, Move left, and Move right reorder only the cards on screen. The engine hand is unchanged. The hand row scrolls, so those controls are the way to rearrange it.

After you discard, the screen waits briefly and calls `ComputerTable.step`. It shows a sentence for that move, then waits again, until it is your turn or the hand is over. When the hand ends, the screen shows this hand's score. Deal the next hand records that score on the `Match` and deals the next seed to the other leader. If the match has a winner, Play again starts a new match.

## Consequences

A test can draw, take a buried discard, lay off on the computer's meld, refuse an illegal move, go out, and watch the computer return the turn. The same session is what the iPhone table runs. The open questions in `docs/RULES.md` stay unanswered.

## Alternatives

A drag that reorders cards would use the same gesture as scrolling the hand. The sort and move controls name the action in words.

Checking a meld again inside the view would give the rules a second home. `HandState` remains the only check.
