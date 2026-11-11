# Stage a meld in a play area

## Status

Accepted

## Context

Andy could not meld in TestFlight build 3. The table already lets you tap cards and press Lay down, and it already lets you tap a meld to lay off the one selected card. That path was not obvious on a phone. ADR 0011 keeps Lay down, Discard, Move left, and Move right, and those buttons still need a selected card.

The engine already decides a legal meld and a legal layoff. `HandState.layDown` and `HandState.layOff` are that decision. The screen must not keep a second copy of the rules.

## Decision

`PlayArea` is an ordered list of cards you have moved out of the hand and not yet played. `TableSession` owns it. `stage`, `unstage`, and `clearPlayArea` move cards between the hand order and that list. The engine hand does not change until Play.

`PlayArea.offer(in:)` asks the engine what those cards can do. Play is enabled only when it is your turn and the offer is a new meld, or a layoff onto exactly one meld already on the table. A group that `layDown` accepts is a new meld, even if those cards would also extend a run. A layoff of more than one card is several `layOff` calls on the same meld, and it counts only when every card is accepted. Two melds that both accept the cards leave Play disabled. Cards that leave out the discard you just took produce `pickedCardNotUsed`, Play stays off, and the screen shows "Include the card you took from the discard."

Drag is the way you stage a card. The moving card is drawn above the table, slightly larger, with a shadow, so the hand's scroller does not clip it. That scroller is also told not to cancel the touch, so the drag still ends on the zone under the finger. The play area highlights while the finger is over it. X puts every staged card back. Play calls `playStaged`, which uses the same offer and then `HandState`. The rest of the drag, including draw, discard, and hand order, is in the section below.

## Consequences

The iPhone table shows the play area between the piles and your hand. Unit tests cover stage, unstage, clear, a short group, a bad group, the heart run, the layoff of the 3 of hearts, the picked-card sentence, and the drag route. A UI test drags that run into the area and presses Play. The open questions in `docs/RULES.md` stay unanswered.

## Alternatives

A tap that both selects and stages would give Discard and Move no card to act on. Those buttons are gone now, and so is the selection. Staging without a drag is the accessibility action.

Copying the meld rules into the view would let Play light up without a turn. `HandState` remains the check. Counting how many melds accept a layoff is the "exactly one" rule, and each accept or refuse still comes from `layOff`.

## Drag the whole turn

Andy playtested the action row and could not follow Lay down, Discard, or Move left and Move right. Those buttons, and the selection they needed, are gone. Sort by suit, sort by rank, X, and Play stay. Presets and the debug link stay. They load a position. They are not plays.

`CardDragRoute.drop` only reads the finger and the frames. It returns one `CardDrop`: draw the stock, take a discard, discard, stage, or place a card at an index in the hand. `TableSession.effect` is the only judge. The white stroke and the committed move both come from that answer. A tap on the stock still draws. A tap on a discard card still takes that card and every card above it.

The hand index counts the card that is moving. The session removes it, then inserts at that same index. The stock and the discard glow while you still need to draw. The discard glows while you may discard. The turn chip keeps saying whose turn it is. When the stock is empty on your draw, a tap on the stock leaves the pile. When the hand is over, a tap on the turn chip deals the next hand.

`PlayArea.layingOff` asks `HandState.layOff` again after each card the engine accepts, so a 5 then a 6 extends a 7-8-9, and a jack then a 10 extends that same run. One rank sort cannot do both. An owed card that fits only after another staged card is laid off first still fails. `layOff` requires the owed card first, and this change adds no engine method.

VoiceOver can draw, take a discard, discard, move a card to the play area, and move a card left or right in the hand. A tap on a hand card no longer selects it. Meld rows are not buttons. Laying off is stage, then Play. Open questions in `docs/RULES.md` stay unanswered.
