# Handoff

- Date: 2026-11-10.
- Branch: `cursor/testflight-upload-8016`.
- What landed. GitHub Actions can upload a signed Release build to TestFlight. The marketing version is 0.1.0. The build number is the Actions run number. The generated Info.plist answers export compliance as no. The simulator job stays unsigned and also makes an unsigned Release archive. The steps for a person are in `docs/TESTFLIGHT.md`.
- What is not done. The real app icon is a later ticket. The current icon is a flat green 1024 by 1024 placeholder. A wider tester list and the playtest checklist are the next ticket. This session did not install a build on a phone. The upload needs the four Actions secrets, and this run could not see whether those secrets exist.
- How to check. `./scripts/check.sh` runs the secret-check self-test, the key-file self-test, the icon check, and the workflow check. On a Mac, `./scripts/archive-unsigned-release.sh` makes the unsigned Release archive. The iOS simulator job runs that script.
- Open questions. They stay in `docs/RULES.md`. This change does not answer them.
