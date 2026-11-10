# Upload a TestFlight build

Use this when you want a build on your iPhone and you do not have Xcode open.

The marketing version comes from `MARKETING_VERSION` in `project.yml`. It starts at 0.1.0. The build number is the GitHub Actions run number for this workflow. The simulator job does not sign the app. This workflow archives without signing, then signs that archive for the App Store when it exports.

The app icon is the flat green square already in the asset catalog. It is 1024 by 1024 and has no transparency. It is a placeholder. A later ticket replaces it.

## Add the four secrets

On GitHub, open the repo Settings, then Secrets and variables, then Actions. Add these secrets. Use these names.

- `ASC_KEY_ID` is the App Store Connect key id.
- `ASC_ISSUER_ID` is the issuer id.
- `ASC_KEY_P8` is the full text of the `.p8` file, including the BEGIN and END lines.
- `APPLE_TEAM_ID` is the 10 character team id.

The workflow stops before it writes the key if any name is missing. The log names the missing secret. The log does not print the value. The key id and the team id are 10 letters or digits. The issuer id is a UUID. The key file has to include the BEGIN and END lines.

## Run the upload

1. Open the Actions tab.
2. Choose TestFlight.
3. Choose Run workflow.
4. Choose the branch you want to build. `main` is the usual choice.
5. Leave "Archive a Release build without signing or uploading" off.
6. Choose Run workflow.

A tag whose name starts with `tf-` runs the same upload. A push to `main` does not. A pull request does not.

The job uses the `macos-26` runner and Xcode 26.6, the same as the simulator job. It installs XcodeGen 2.46.0, generates the Xcode project, and archives the Release configuration without signing. Export then signs that archive for the App Store and uploads it. The archive command does not set a team, a signing identity, or a provisioning profile, and it does not turn signing on. A development profile needs a registered device, and this team has none. The export plist uses method `app-store-connect`, signing style automatic, destination upload, and the team id from `APPLE_TEAM_ID`. The API key has the Admin role, so Xcode can create the distribution certificate and the App Store profile on this export. An App Store profile does not list devices. The key file is mode 0600 in the runner temp directory. A last step deletes that file and the export options, including when a later step fails.

Uploads wait for each other. A second run does not cancel the first, and it does not create the certificate at the same time.

## Find the build

Open App Store Connect, then the Rummy 500 app, then TestFlight, then the iOS builds. The new row shows Processing, then Ready to Test. Processing can take several minutes after the GitHub job is green. The build number on that row is the Actions run number. The version is 0.1.0 until `project.yml` changes.

## Add yourself as an internal tester

An internal tester is a person on the App Store Connect team. You do this once.

1. Open Users and Access.
2. Invite yourself with the Apple ID you use on the iPhone, if you are not already a user on the team.
3. Open the Rummy 500 app, then TestFlight, then Internal Testing.
4. Add yourself to the internal group.
5. On the iPhone, install TestFlight, accept the invite, and install the build.

An external group needs a privacy policy URL and a beta review. Internal testing does not. Use the internal group for this first build.

## Try the archive without the secrets

Run the workflow and turn on "Archive a Release build without signing or uploading". That job builds a Release archive and does not upload it. Pull requests run that same archive in the iOS simulator job, after the tests. The archive check fails if the marketing version is not 0.1.0 or if export compliance is missing.

## When App Store Connect rejects the upload

- The icon is missing or has transparency. This repo checks that `AppIcon.png` is 1024 by 1024 and has no transparency. If that check fails, fix the icon before you run the upload.
- The build number was already uploaded. Run the workflow again. The next run number is a new build.
- A secret is incomplete. The failing step names `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, or `APPLE_TEAM_ID`. Put the whole `.p8` file in `ASC_KEY_P8`.
- Export compliance is still waiting. The generated Info.plist sets `ITSAppUsesNonExemptEncryption` to NO, so this demo does not stop on that prompt.
- Xcode reports conflicting provisioning settings. The archive command must not pass a signing identity or a provisioning profile. `./scripts/check.sh` fails when the archive command passes either one.
- Xcode says the team has no devices, or that no iOS App Development profile exists. The archive stays unsigned. Distribution signing happens at export. `./scripts/check.sh` fails if the archive command asks for a development profile.
- The upload went to an external group. Use Internal Testing for this build.
