# Handoff

- Date: 2026-11-10.
- Branch: `cursor/testflight-automatic-signing-8dba`.
- What landed. The TestFlight archive no longer passes a signing identity. Automatic signing stays on. The team still comes from `APPLE_TEAM_ID`. The script removes the `-` identity from the generated project so the app target does not keep a manual identity. The marketing version is still 0.1.0. The build number is still the Actions run number. Export still uploads with method `app-store-connect`.
- What is not done. This session did not run the TestFlight workflow. Andy runs that after merge. The real app icon is still a later ticket.
- How to check. `./scripts/check.sh`. The workflow check fails if the archive command passes `CODE_SIGN_IDENTITY` or a provisioning profile.
- Open questions. They stay in `docs/RULES.md`. This change does not answer them.
