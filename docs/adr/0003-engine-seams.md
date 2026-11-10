# Keep the engine to a seeded generator and named seams

## Status

Accepted

## Context

Cards, the deal, melds, turns, and scoring belong to later tickets. `docs/RULES.md` still has open questions, including an empty stock, a discard card that cannot be used, and the score of a low ace. A game-state type would have to answer those questions.

Two design sketches were started for this choice. Neither had written a file when this decision was recorded, so there was nothing to graft. The shape below is the one that keeps a single public list and a real generator, and that leaves those questions out of the code.

## Decision

`Seed` is the `UInt64` a later shuffle or the computer opponent will pass in. `SeededGenerator` is SplitMix64 and conforms to `RandomNumberGenerator`. The same seed returns the same stream. Tests lock the first draws of seed 0 and seed 1 to that algorithm. `RuleArea` names the five homes later tickets will fill. Those homes have no functions yet.

Views do not call the engine. `DemoSession.generator(seed:)` is the app module's only door to it, and the hosted app test checks that the seed is honored.

## Consequences

A test can replay a stream without pinning Swift's shuffle. A later ticket adds a type next to `RuleArea`. It does not have to delete a turn machine, and it does not inherit an answer to an open rule.

## Alternatives

A protocol for each area, and a state machine with phases, both publish operations the demo cannot perform yet or freeze an open rule. An empty package with only the generator would leave the five homes unnamed, so the next change would invent a second list.
