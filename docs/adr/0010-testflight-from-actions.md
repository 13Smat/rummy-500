# Upload TestFlight builds from GitHub Actions

## Status

Accepted

## Context

Andy needs a build on his iPhone without opening Xcode. App Store Connect already has the app `com.13smat.rummy500`. The simulator job, and `scripts/check_project_yml.py`, keep `CODE_SIGNING_ALLOWED` at NO and refuse a `DEVELOPMENT_TEAM` in `project.yml`. The archive stays unsigned. Distribution signing happens when that archive is exported.

The values that can sign that archive are GitHub Actions secrets. The names are `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, and `APPLE_TEAM_ID`. The API key has the Admin role.

## Decision

`.github/workflows/testflight.yml` runs when someone starts it by hand, or when someone pushes a tag that starts with `tf-`. A push to `main` does not run it. A pull request does not run it.

The job writes the `.p8` into the runner temp directory as mode 0600. It generates the Xcode project with XcodeGen 2.46.0. It archives the Release configuration for a generic iOS device with `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO`. That command does not pass a team, a signing identity, a provisioning profile, or `-allowProvisioningUpdates`. An archive that turns automatic signing on asks Apple for an iOS App Development profile, and that profile needs a registered device. This team has none. `github.run_number` is passed as `CURRENT_PROJECT_VERSION`. The marketing version stays `MARKETING_VERSION` in `project.yml`, which starts at 0.1.0. `project.yml` still sets the identity to `-` and leaves signing off, so the simulator job stays unsigned.

`xcodebuild -exportArchive` reads an export plist whose method is `app-store-connect`, whose signing style is automatic, whose destination is `upload`, and whose team id is the `APPLE_TEAM_ID` secret. The same API key is passed as `-authenticationKeyPath`, `-authenticationKeyID`, and `-authenticationKeyIssuerID`, with `-allowProvisioningUpdates`. Xcode cloud signing creates the distribution certificate and the App Store profile on that export. An App Store profile contains a distribution certificate and does not list devices. The export does not name a certificate or a profile. The certificate stays in Apple's cloud, so a later run does not create another one and git never stores the private key. Fastlane match is not used. Match would keep a second copy of the certificate in another repo, and this key can already create the certificate.

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

Passing `CODE_SIGN_IDENTITY` as Apple Distribution, or switching the archive to manual signing, would also hit the RummyEngine package. The package has no profile. The archive stays unsigned so that override never lands on the package.

Registering an iPhone would let the archive create a development profile. Andy uses Windows, so adding a device is a poor path. Export signs with an App Store profile instead.

## Sources

Actions run 42919110305 archived with automatic signing and stopped because the team has no devices and Xcode found no iOS App Development profile for `com.13smat.rummy500`.

Apple's account help says creating a development profile starts from an App ID, a development certificate, and one or more registered devices, then asks you to select those devices. https://developer.apple.com/help/account/provisioning-profiles/create-a-development-provisioning-profile/

The same help says an App Store Connect profile contains one distribution certificate. The steps do not select devices. If you choose automatically manage signing when you upload, Xcode manages that profile. The required role is Account Holder or Admin. https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/

WWDC 2021 session 10204, "Distribute apps in Xcode with cloud signing", says the upload step turns the archive into an IPA and signs it for distribution. With automatic signing, the certificate and the private key stay in the cloud. The Mac does not need a distribution certificate installed. https://developer.apple.com/videos/play/wwdc2021/10204/

A write-up updated 27 October 2026, using Xcode 26.5, archived with `CODE_SIGNING_ALLOWED=NO`. `codesign` reported that the app was not signed. `xcodebuild -exportArchive` on that archive then looked up an iOS App Store profile. It did not reject the archive for having no signature. The same write-up says automatic signing on CI is `-allowProvisioningUpdates` plus `-authenticationKeyPath`, `-authenticationKeyID`, and `-authenticationKeyIssuerID`, which `xcodebuild -help` lists. That export was tried without an Apple account, so it stopped on the missing profile. It was not a finished upload. https://codezup.com/deploying-ios-apps-on-cloud-platforms/
