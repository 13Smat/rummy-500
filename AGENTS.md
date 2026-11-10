# How agents work in this repo

## Skills and style
- pstack (github.com/backnotprop/pstack) is vendored under .cursor/skills/. Use /poteto-mode for all work in this repo, and use subagents for parallel research and self-contained tasks.
- Reach for the matching pstack skill instead of improvising: /architect before non-trivial design, /how before changing code you have not read, /tdd for rules and bugs, /interrogate or /blast-radius before risky merges, /technical-writing, /bro and /unslop for anything a person reads.
- Write for a reader: plain words, no jargon in player-facing text or docs, short README that gets someone running in 5 minutes.

## One ticket, one agent, one PR
- Each ticket is done by its own fresh agent on its own branch.
- Before pushing: rebase onto the latest main, fix conflicts, rerun every check, then open a PR. Do not merge your own PR; Builder reviews and merges PRs one at a time.
- Small commits with meaningful messages. Never force-push main.
- Cloud coding agents use the newest available Grok model by default.

## Proof, not review-only passes
- Before calling work done, run the real checks: unit tests, lint, build, and any verification specs. Paste the results in the PR.
- Every bug found gets a regression test or a lint rule.
- Never remove CI or branch protection without asking Andy first.

## Playable in the same PR
- Every new play action or rule must be usable or testable in the same PR: reachable from the app's UI or from a loadable test scene (a saved deal or mid-hand position you can open in debug builds).

## Architecture rules
- The Rummy 500 rules engine is a pure Swift package with no UI or Apple-only imports, so it builds and its tests run with `swift test` on Linux and macOS. The SwiftUI app depends on it; game logic never lives in views.
- Deterministic by design: shuffles and the computer opponent use a seeded random generator so any hand can be replayed exactly in a test or test scene.
- Model the game state with types that make illegal states hard to represent (cards, melds, turn phase). Validate at boundaries; fail loudly in debug, safely in release.
- Where turn order or hand-ending logic gets tricky, write it down as a state diagram (pstack /statechart) before coding.
- docs/DESIGN.md (or the written rules doc) is the source of product intent. Record decisions as short files in docs/adr/, keep docs/STATUS.md and CHANGELOG.md current, and leave a handoff note in docs/handoff/ at the end of a session.

## Safety
- No secrets, signing certificates, or API keys in git. Least privilege everywhere.
- No accounts, tracking, ads, or network calls in the demo.

## This checkout

pstack 0.15.36 is vendored at commit `08547969e1dffaa6457ea65141cc62c1d9a2eef1` from https://github.com/backnotprop/pstack. The skill folders live in `.cursor/skills/` so a cloud agent can load them. The MIT license is `.cursor/skills/pstack-LICENSE`. The pin is also in `.cursor/pstack-vendor.json`.

### Layout

`Packages/RummyEngine` is the pure Swift rules engine. `App/Rummy500` is the SwiftUI iPhone app. `project.yml` is the Xcode project. Do not hand-edit `Rummy500.xcodeproj`. It is generated and gitignored. `docs/RULES.md` is the product rules. Open questions in that file stay unanswered until Andy decides them. `docs/adr/` records decisions. `docs/STATUS.md` and `CHANGELOG.md` say what is done. `docs/handoff/` is the session note.

### Commands

From the repo root, run the engine tests and the local checks.

```
swift test --package-path Packages/RummyEngine
./scripts/check.sh
```

On a Mac with Xcode 26 and XcodeGen 2.46.0, generate the project and open it.

```
xcodegen generate
open Rummy500.xcodeproj
```

Run the Rummy500 scheme on an iPhone simulator. The screen shows the name Rummy 500.

### CI

`.github/workflows/ci.yml` runs on every pull request. The Ubuntu job installs Swift 6.4.2 and runs `./scripts/check.sh`, which includes `swift test`. The macOS job uses the `macos-26` runner and Xcode 26.6. It installs XcodeGen 2.46.0, generates the project, builds the app for an iPhone simulator, and runs the app tests. Signing stays off until a later Apple ticket. The workflow does not use a larger macOS runner.

### Engine boundary

Later tickets add cards, the deal, melds, turns, and scoring inside `Packages/RummyEngine`. The app reads that package. Views do not grow rule logic. Shuffles and the computer opponent take a `SeededGenerator`. Leave every open question in `docs/RULES.md` unanswered in code.
