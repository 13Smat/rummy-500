# Handoff

- Date: 2026-11-10.
- Branch: `cursor/testflight-distribution-export-8dba`.
- What landed. The TestFlight archive no longer signs. Export signs that archive for App Store distribution with the existing plist and the App Store Connect key. The archive command still must not pass a signing identity. It also must not ask for a development profile. The marketing version is still 0.1.0. The build number is still the Actions run number.
- What is not done. This session did not run the TestFlight workflow. Andy merges, then a later step pushes the `tf-` tag. The real app icon is still a later ticket.
- How to check. `./scripts/check.sh`. The workflow check fails if the archive command passes `CODE_SIGN_IDENTITY`, a provisioning profile, or a setting that asks for a development profile.
- Open questions. They stay in `docs/RULES.md`. This change does not answer them.
