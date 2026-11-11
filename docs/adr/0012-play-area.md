# Stage a meld in a play area

## Status

Accepted

## Context

Andy could not meld in TestFlight build 3. The table already lets you tap cards and press Lay down, and it already lets you tap a meld to lay off the one selected card. That path was not obvious on a phone. ADR 0011 keeps Lay down, Discard, Move left, and Move right, and those buttons still need a selected card.

The engine already decides a legal meld and a legal layoff. `HandState.layDown` and `HandState.layOff` are that decision. The screen must not keep a second copy of the rules.

## Decision

`PlayArea` is an ordered list of cards you have moved out of the hand and not yet played. `TableSession` owns it. `stage`, `unstage`, and `clearPlayArea` move cards between the hand order and that list. The engine hand does not change until Play.

`PlayArea.offer(in:)` asks the engine what those cards can do. Play is enabled only when it is your turn and the offer is a new meld, or a layoff onto exactly one meld already on the table. A group that `layDown` accepts is a new meld, even if those cards would also extend a run. A layoff of more than one card is several `layOff` calls on the same meld, and it counts only when every card is accepted. Two melds that both accept the cards leave Play disabled. Cards that leave out the discard you just took produce `pickedCardNotUsed`, Play stays off, and the screen shows "Include the card you took from the discard."

Drag is the way you stage a card. `DraggedCard` is the payload, and `CardDragRoute` maps its origin and the drop zone to stage or unstage. The finger is tracked in the table's coordinate space. Each zone reports its frame there, and the route picks the zone under the finger. A later ticket can add the discard pile or a gap in the hand by reporting another frame. The moving card is drawn above the table, slightly larger, with a shadow, so the hand's scroller does not clip it. That scroller is also told not to cancel the touch, so the drag still ends on the zone under the finger. The play area highlights while the finger is over it.

A finger tap on a hand card still selects it, so Lay down, Discard, Move left, and Move right keep a gesture. The VoiceOver action "Move to play area" stages that card. A tap on a staged card, and the action "Return to hand", put that one card back. The X button puts every staged card back. Play calls `playStaged`, which uses the same offer and then `HandState`.

## Consequences

The iPhone table shows the play area between the piles and your hand. Unit tests cover stage, unstage, clear, a short group, a bad group, the heart run, the layoff of the 3 of hearts, the picked-card sentence, and the drag route. A UI test drags that run into the area and presses Play. The open questions in `docs/RULES.md` stay unanswered.

## Alternatives

A tap that both selects and stages would give Discard and Move no card to act on. The finger tap stays a selection. Staging without a drag is the accessibility action.

Copying the meld rules into the view would let Play light up without a turn. `HandState` remains the check. Counting how many melds accept a layoff is the "exactly one" rule, and each accept or refuse still comes from `layOff`.
