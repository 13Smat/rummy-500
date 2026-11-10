# Upload TestFlight builds from GitHub Actions

## Status

Accepted

## Context

Andy needs a build on his iPhone without opening Xcode. App Store Connect already has the app `com.13smat.rummy500`. The simulator job, and `scripts/check_project_yml.py`, keep `CODE_SIGNING_ALLOWED` at NO and refuse a `DEVELOPMENT_TEAM` in `project.yml`. Signing has to turn on for one archive and stay off for every other build.

The values that can sign that archive are GitHub Actions secrets. The names are `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, and `APPLE_TEAM_ID`. The API key has the Admin role.

## Decision

`.github/workflows/testflight.yml` runs when someone starts it by hand, or when someone pushes a tag that starts with `tf-`. A push to `main` does not run it. A pull request does not run it.

The job writes the `.p8` into the runner temp directory as mode 0600. It generates the Xcode project with XcodeGen 2.46.0. It archives the Release configuration for a generic iOS device. That command sets automatic signing. It passes `DEVELOPMENT_TEAM` from `APPLE_TEAM_ID`. It does not pass `CODE_SIGN_IDENTITY` or a provisioning profile. A command-line build setting applies to the app and to the RummyEngine package. The package is signed automatically, so a manual distribution identity makes Xcode stop both targets with a conflicting provisioning error. `project.yml` still sets the identity to `-` and leaves signing off, so the simulator job stays unsigned. Before the signed archive, the script deletes `CODE_SIGN_IDENTITY` from the generated project. The app target would otherwise keep `-` while the archive sets automatic signing. Xcode reports a conflict when automatic signing meets a manual identity, and `-` is still an identity. `github.run_number` is passed as `CURRENT_PROJECT_VERSION`. The marketing version stays `MARKETING_VERSION` in `project.yml`, which starts at 0.1.0.

`xcodebuild -exportArchive` reads an export plist whose method is `app-store-connect`, whose signing style is automatic, whose destination is `upload`, and whose team id is the `APPLE_TEAM_ID` secret. The same API key is passed as `-authenticationKeyPath`, `-authenticationKeyID`, and `-authenticationKeyIssuerID`, with `-allowProvisioningUpdates`. Xcode creates the distribution certificate and the profile. The export does not name a certificate or a profile. Fastlane match is not used. Match would keep a second copy of the certificate in another repo, and this key can already create the certificate.

A last step always deletes the key file and the export plist.

The generated Info.plist sets `ITSAppUsesNonExemptEncryption` to NO. The app makes no network call. The 1024 by 1024 icon already in the catalog has no transparency. It is a flat green placeholder. The real icon is a later ticket.

Pull requests also build an unsigned Release archive with `scripts/archive-unsigned-release.sh`. The workflow's dry-run input runs that same script. The archive check requires marketing version 0.1.0 and the encryption answer. Linux checks the secret script, the key-file mode, the icon, and the workflow triggers. Those checks do not need the secrets.

Uploads share one concurrency group and do not cancel a run that is already signing. Two runs cannot create the certificate at the same time. A later run still gets its own build number.

## Consequences

The first green upload can create a distribution certificate on the Apple team. The project file still has signing off, so the simulator job does not need the secrets. Someone has to add the four secrets before an upload works. The job names a missing secret and does not print the value.

`docs/adr/0001-native-swift-and-a-pure-engine.md` left signing and the bundle id for a later ticket. This decision settles that wait. The bundle id is `com.13smat.rummy500`, which App Store Connect already uses.

## Alternatives

Turning signing on in `project.yml` would make a local build and the simulator job look for a team. The project check forbids that.

Uploading on every push to `main` would spend a Mac runner and a build number on each merge. The upload stays a manual action.

Fastlane match would add a certificate repo. The Admin API key and `-allowProvisioningUpdates` already cover cloud-managed signing, so a second tool is not part of this path.

Passing `CODE_SIGN_IDENTITY` as Apple Distribution, or switching the archive to manual signing, would also hit the RummyEngine package. The package has no profile. Automatic signing on the app target, with no identity on the command line, leaves the certificate and the profile to Xcode.
