# Generate the Xcode project and do not commit it

## Status

Accepted

## Context

A hand-edited `project.pbxproj` conflicts when two branches add a file. The tickets ask for an XcodeGen `project.yml` so the project is not maintained by hand.

## Decision

`project.yml` is the source of the Xcode project. A Mac checkout and the macOS CI job run XcodeGen 2.46.0. `Rummy500.xcodeproj` is gitignored. This repo does not commit the generated project.

## Consequences

A new Mac needs XcodeGen before Xcode will open the app. That step is in the README. A target change shows up as a YAML diff. If XcodeGen and Xcode disagree, the fix belongs in `project.yml` or in the pinned generator version, and the macOS job is where that disagreement shows up.

## Alternatives

Committing the generated project would let a person open Xcode without installing XcodeGen. The generated file would still change under them, and a hand edit would drift from `project.yml`. One install step costs less than that drift.
