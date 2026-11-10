# Use a pure Swift engine and a SwiftUI iPhone app

## Status

Accepted

## Context

The demo has to reach TestFlight on iPhone, and the rules have to be testable on Linux, where the agents for this repo run. Putting the rules inside the iOS app would tie every test to a Mac.

## Decision

The rules live in the Swift package `Packages/RummyEngine`. That package imports only the Swift standard library. The iPhone app is SwiftUI and depends on the package. iPad runs that iPhone app in compatibility mode, because `TARGETED_DEVICE_FAMILY` is 1. The deployment target is iOS 18. The bundle id `com.13smat.rummy500` is a placeholder until the Apple ticket. This branch does not sign the app. The app makes no network call, and it has no account and no tracking.

## Consequences

A later ticket can test a rule with `swift test` on Linux. Building the app still needs a Mac. Signing and a real bundle id wait for the Apple ticket.
