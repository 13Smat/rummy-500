---- MODULE RummyTurn ----
EXTENDS Integers

VARIABLES phase, stock, pile, active, waiting, seat

vars == <<phase, stock, pile, active, waiting, seat>>

Other(s) == IF s = "you" THEN "computer" ELSE "you"

TypeOK ==
  /\ phase \in {"draw", "owe", "play", "out", "empty"}
  /\ stock \in 0..1
  /\ pile \in 0..2
  /\ active \in 0..3
  /\ waiting \in 0..3
  /\ seat \in {"you", "computer"}

Init ==
  /\ phase = "draw"
  /\ stock = 1
  /\ pile = 1
  /\ active = 1
  /\ waiting = 1
  /\ seat = "you"

DrawStock ==
  /\ phase = "draw"
  /\ stock > 0
  /\ active < 3
  /\ phase' = "play"
  /\ stock' = stock - 1
  /\ active' = active + 1
  /\ UNCHANGED <<pile, waiting, seat>>

TakeTop ==
  /\ phase = "draw"
  /\ pile > 0
  /\ active < 3
  /\ phase' = "owe"
  /\ pile' = pile - 1
  /\ active' = active + 1
  /\ UNCHANGED <<stock, waiting, seat>>

TakeDeep ==
  /\ phase = "draw"
  /\ pile > 1
  /\ active + pile <= 3
  /\ phase' = "owe"
  /\ active' = active + pile
  /\ pile' = 0
  /\ UNCHANGED <<stock, waiting, seat>>

UsePicked ==
  /\ phase = "owe"
  /\ active > 1
  /\ phase' = "play"
  /\ active' = active - 1
  /\ UNCHANGED <<stock, pile, waiting, seat>>

MeldSome ==
  /\ phase = "play"
  /\ active > 1
  /\ active' = active - 1
  /\ UNCHANGED <<phase, stock, pile, waiting, seat>>

MeldAll ==
  /\ phase \in {"play", "owe"}
  /\ active >= 1
  /\ phase' = "out"
  /\ active' = 0
  /\ UNCHANGED <<stock, pile, waiting, seat>>

DiscardPass ==
  /\ phase = "play"
  /\ active > 1
  /\ pile < 2
  /\ phase' = "draw"
  /\ waiting' = active - 1
  /\ active' = waiting
  /\ pile' = pile + 1
  /\ seat' = Other(seat)
  /\ UNCHANGED stock

DiscardLast ==
  /\ phase = "play"
  /\ active = 1
  /\ phase' = "out"
  /\ active' = 0
  /\ pile' = IF pile < 2 THEN pile + 1 ELSE pile
  /\ UNCHANGED <<stock, waiting, seat>>

EndEmpty ==
  /\ phase = "draw"
  /\ stock = 0
  /\ phase' = "empty"
  /\ UNCHANGED <<stock, pile, active, waiting, seat>>

Done ==
  /\ phase \in {"out", "empty"}
  /\ UNCHANGED vars

Next ==
  \/ DrawStock
  \/ TakeTop
  \/ TakeDeep
  \/ UsePicked
  \/ MeldSome
  \/ MeldAll
  \/ DiscardPass
  \/ DiscardLast
  \/ EndEmpty
  \/ Done

Spec == Init /\ [][Next]_vars

AnEmptyHandMeansYouWentOut ==
  (active = 0) <=> (phase = "out")

TheStockEndsOnlyWhenItIsEmpty ==
  phase = "empty" => stock = 0

ThePickedCardStaysUntilYouPlayIt ==
  phase = "owe" => active > 0

TheTurnPassesOnlyAfterADiscard ==
  [][seat' /= seat =>
      phase = "play" /\ phase' = "draw" /\ active > 1]_vars

TheLastCardDiscardGoesOut ==
  [][phase = "play" /\ active = 1 /\ phase' /= phase =>
      phase' = "out" /\ active' = 0]_vars

APickIsNotYetAFinishedTurn ==
  [][phase' = "owe" => phase = "draw" /\ active' > active]_vars

DecliningEndsOnlyAnEmptyStock ==
  [][phase' = "empty" => phase = "draw" /\ stock = 0]_vars

StayFinished ==
  phase \in {"out", "empty"} =>
    /\ phase' = phase
    /\ stock' = stock
    /\ pile' = pile
    /\ active' = active
    /\ waiting' = waiting
    /\ seat' = seat

YouDoNotLeaveAFinishedHand == [][StayFinished]_vars

====
