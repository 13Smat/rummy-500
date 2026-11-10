# Rummy 500

This is a two-player Rummy 500 demo for iPhone. You play against the computer. A debug build deals a seeded hand and lists both hands, the stock count, the discard, and the largest legal melds in each hand. It scores a scripted hand and shows the match totals. It also steps through a scripted hand, one move at a time, and shows the score when that hand ends. Under that, it plays a seeded match with the computer on both seats. Next move takes one action. Auto-play runs until someone reaches 500.

## Run the app on a Mac

You need Xcode 26 and XcodeGen 2.46.0.

1. Clone the repo and enter the directory.
2. Install XcodeGen with `brew install xcodegen`.
3. Generate the Xcode project with `xcodegen generate`.
4. Open it with `open Rummy500.xcodeproj`.
5. Choose the Rummy500 scheme and an iPhone simulator.
6. Press Run.

The launch screen shows Rummy 500. The first screen shows Rummy 500, and under it, You against the computer. A debug build adds a seed and a Deal button under that line. Dealing lists your 13 cards, the computer's 13 cards, the largest legal melds in each hand, the stock count, and the face-up discard. Under that list, the debug build shows a sample score, then a scripted hand. Press Next to take one draw, meld, layoff, or discard. The last step shows both hand scores and the match totals. Under the scripted hand, the debug build shows a computer match. Press Next move for one action, or Auto-play to finish the match.

Signing is off until a later Apple ticket. Run the app in the simulator. `project.yml` is the project file we keep. `Rummy500.xcodeproj` is generated, and git ignores it.

## Run the engine tests

From the repo root:

```
swift test --package-path Packages/RummyEngine
```

On Linux, install Swift 6.4.2 and run the same command. `./scripts/check.sh` runs that test and checks the project file and the rules sheet.

You should see the XCTest summary with every test passing.

## Where to read next

The rules are in `docs/RULES.md`. Questions that are still open for Andy are at the bottom of that file. `docs/STATUS.md` says what this branch contains and what later tickets own.
