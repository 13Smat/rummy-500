# Rummy 500

This is a two-player Rummy 500 demo for iPhone. You play against the computer. The first screen is the table. It shows your hand, the computer's face-down hand, the stock, the discard pile, both players' melds, the match scores, and whose turn it is. Drag the stock or a discard into your hand to draw. Drag cards into the play area and press Play to meld or lay off. Drag one card onto the discard pile to discard. Drag a card sideways to reorder your hand. Sort by suit and sort by rank are there when you want them. The computer then plays one move at a time. When the hand ends, tap the turn chip to deal the next hand. A menu loads a fresh deal, a mid-hand, or a long discard pile. A debug build still lists a seeded deal, a sample score, and a scripted hand. Under that, it plays a seeded match with the computer on both seats. Next move takes one action. Auto-play runs until someone reaches 500.

## Run the app on a Mac

You need Xcode 26 and XcodeGen 2.46.0.

1. Clone the repo and enter the directory.
2. Install XcodeGen with `brew install xcodegen`.
3. Generate the Xcode project with `xcodegen generate`.
4. Open it with `open Rummy500.xcodeproj`.
5. Choose the Rummy500 scheme and an iPhone simulator.
6. Press Run.

The launch screen shows Rummy 500. The table shows your cards face up, the computer's cards face down, the stock, the spread discard, the melds, the scores, and whose turn it is. The stock and the discard glow when it is time to draw, and the discard glows when it is time to discard. Drag a card to draw, meld, discard, or move it in your hand. After you discard, the computer plays. Tap the turn chip when the hand is over. Choose Fresh deal, Mid-hand, or Long discard to change the position. A debug build adds a Debug button. That screen lists a seeded deal, a sample score, and a scripted hand. Press Next to take one draw, meld, layoff, or discard. The last step shows both hand scores and the match totals. Under the scripted hand, the debug build shows a computer match. Press Next move for one action, or Auto-play to finish the match.

Run the app in the simulator. That build is unsigned. `docs/TESTFLIGHT.md` is how you upload a signed build to your iPhone. `project.yml` is the project file we keep. `Rummy500.xcodeproj` is generated, and git ignores it.

## Run the engine tests

From the repo root:

```
swift test --package-path Packages/RummyEngine
```

On Linux, install Swift 6.4.2 and run the same command. `./scripts/check.sh` runs that test and checks the project file and the rules sheet.

You should see the XCTest summary with every test passing.

## Where to read next

The rules are in `docs/RULES.md`. Questions that are still open for Andy are at the bottom of that file. `docs/STATUS.md` says what this branch contains and what later tickets own.
