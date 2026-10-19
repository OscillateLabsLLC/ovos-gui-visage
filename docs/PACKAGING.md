# macOS packaging and release

The macOS app ships as a zip on each GitHub release, signed with a Developer ID certificate and
notarised by Apple, and installs through the Homebrew cask in
[OscillateLabsLLC/homebrew-tap](https://github.com/OscillateLabsLLC/homebrew-tap). It is not a
Mac App Store app: the sandbox is off, because the app opens local sockets and reads
`~/.cache/ovos_gui`.

## The flow

1. A conventional commit lands on `main`. release-please (`.github/workflows/release_please.yml`)
   opens or updates its release PR, which bumps `pubspec.yaml` and `CHANGELOG.md`.
2. A maintainer merges the release PR. release-please tags `v<version>` and publishes a GitHub
   release. It uses `RELEASE_PLEASE_TOKEN`, a personal access token, since a release made with
   `GITHUB_TOKEN` does not start other workflows.
3. `.github/workflows/release.yml` starts on `release: published`:
   1. It checks out the tag and stops if `pubspec.yaml` does not have the tag's version.
   2. It imports the Developer ID p12 into a temporary keychain.
   3. It runs `tool/release_macos.sh`, which builds a Release app unsigned with `xcodebuild` (the
      `build.yml` pattern) and then signs it. The frameworks are signed first and the app last,
      with the hardened runtime, a secure timestamp and `macos/Runner/Release.entitlements`.
      The script zips the app with `ditto`, sends the zip to `xcrun notarytool submit --wait`
      with the App Store Connect API key, staples the ticket, zips again and writes the sha256.
   4. It checks the app with `spctl -a -vv` and uploads
      `ovos-gui-visage-<version>-macos.zip` and its `.sha256` file to the release.
   5. It deletes the temporary keychain and the API key, also when an earlier step fails.
4. The `homebrew-tap` job checks out the tap with `TAP_GITHUB_TOKEN`, writes the new `version`
   and `sha256` into `Casks/ovos-gui-visage.rb`, and pushes to the tap's `main`. The tap is the
   only repository where a bot pushes to `main`; the cask only follows releases this workflow
   built and notarised.

To build a tag again, run the Release workflow by hand (`workflow_dispatch`) with the tag. The
upload replaces the assets and the tap job does nothing when the checksum did not change.

## One-time setup (the owner only)

| Step | Where | Result |
|---|---|---|
| Create a **Developer ID Application** certificate for team H5BYD9K74S. Make the CSR in Keychain Access (Certificate Assistant > Request a Certificate From a Certificate Authority), upload it, download the `.cer` and open it. | developer.apple.com > Certificates, IDs & Profiles | `Developer ID Application: … (H5BYD9K74S)` in the login keychain |
| Export the certificate **with its private key** as a `.p12` with a strong password. | Keychain Access > My Certificates > Export | `DeveloperID.p12` and its password |
| Create an App Store Connect API key with the **Developer** role. Download the `.p8` (you can download it one time only) and note the Key ID and the Issuer ID. | appstoreconnect.apple.com > Users and Access > Integrations > App Store Connect API | `AuthKey_<KEYID>.p8`, Key ID, Issuer ID |
| Create the GitHub repositories `OscillateLabsLLC/ovos-gui-visage` and `OscillateLabsLLC/homebrew-tap`, then push both local repos. | github.com | Both repos on `main` |
| Create a fine-grained token with **Contents: read and write** on `homebrew-tap` only. | GitHub > Settings > Developer settings | The `TAP_GITHUB_TOKEN` value |
| Add the six secrets below, plus `RELEASE_PLEASE_TOKEN` if it is not there yet. | ovos-gui-visage > Settings > Secrets and variables > Actions | The workflow can sign, notarise and push |
| Store notary credentials in the keychain for local releases. | your Mac | The `NOTARY_PROFILE` value |

The secrets of the ovos-gui-visage repository:

| Secret | Value |
|---|---|
| `MACOS_CERT_P12_BASE64` | `base64 -i DeveloperID.p12 \| pbcopy`, then paste |
| `MACOS_CERT_PASSWORD` | the p12 export password |
| `NOTARY_KEY_P8_BASE64` | `base64 -i AuthKey_<KEYID>.p8 \| pbcopy`, then paste |
| `NOTARY_KEY_ID` | the Key ID, for example `2X9R4HXF34` |
| `NOTARY_ISSUER_ID` | the Issuer ID, a UUID |
| `TAP_GITHUB_TOKEN` | the fine-grained token for `homebrew-tap` |

Notary credentials for local use, with the same API key:

```bash
xcrun notarytool store-credentials ovos-gui-visage-notary \
  --key AuthKey_<KEYID>.p8 --key-id <KEYID> --issuer <ISSUER_ID>
```

## Local builds

```bash
tool/release_macos.sh                                    # ad hoc signature, no notarisation
SIGN_IDENTITY="Developer ID Application" NOTARY_PROFILE=ovos-gui-visage-notary tool/release_macos.sh
```

The zip and `<zip>.sha256` go to `build/release/`. An ad hoc build has the hardened runtime
(`codesign -dv` shows `flags=0x10002(adhoc,runtime)`), but Gatekeeper rejects it
(`spctl -a` prints `rejected`). This is expected: only a notarised Developer ID build passes.
A real identity with no notary credentials gives a signed app that is not notarised, and the
script says so.

## Release checklist

1. Merge the release-please PR on `main`.
2. Wait for the Release workflow to go green on the new tag. If notarisation fails, run
   `xcrun notarytool log <submission-id>` with the same credentials to see why.
3. Check the download:

   ```bash
   curl -LO https://github.com/OscillateLabsLLC/ovos-gui-visage/releases/download/v<version>/ovos-gui-visage-<version>-macos.zip
   shasum -a 256 -c <(curl -L https://github.com/OscillateLabsLLC/ovos-gui-visage/releases/download/v<version>/ovos-gui-visage-<version>-macos.zip.sha256)
   ditto -x -k ovos-gui-visage-<version>-macos.zip .
   spctl -a -vv ovos_gui_visage.app      # accepted, source=Notarized Developer ID
   xcrun stapler validate ovos_gui_visage.app
   ```

4. Check the tap commit on `homebrew-tap` `main`, then:

   ```bash
   brew update
   brew install --cask oscillatelabsllc/tap/ovos-gui-visage   # or brew upgrade --cask
   brew audit --cask --online oscillatelabsllc/tap/ovos-gui-visage
   ```

   `brew audit` needs the release URL to exist, so it can run only after the first release.
