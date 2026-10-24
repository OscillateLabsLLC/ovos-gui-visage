# Packaging and release

The macOS app ships as a zip on each GitHub release, signed with a Developer ID certificate and
notarised by Apple, and installs through the Homebrew cask in
[OscillateLabsLLC/homebrew-tap](https://github.com/OscillateLabsLLC/homebrew-tap). It is not a
Mac App Store app: the sandbox is off, because the app opens local sockets and reads
`~/.cache/ovos_gui`.

Linux ships as `.deb` packages for amd64 and arm64 on each GitHub release, installed with plain apt on
Debian 12, Raspberry Pi OS Bookworm and Ubuntu 24.04 ([Linux packages](#linux-packages)). The web
build ships as a container image on ghcr.io with each release, for amd64 and arm64, for a browser on
any machine.

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
5. Alongside, without waiting for the macOS job, the `container` job builds `sidecar/Dockerfile` for
   `linux/amd64` and `linux/arm64` and pushes `ghcr.io/oscillatelabsllc/ovos-gui-visage` tagged
   `<version>`, `<major>.<minor>`, `<major>` and `latest`, with `GITHUB_TOKEN`. The Flutter stage runs
   once on the runner's own platform, since the web build is the same for both; only the nginx stage
   is per platform, so nothing runs under emulation.
6. Also alongside, the `linux` job runs `.github/workflows/linux_deb.yml` on the tag: it builds and
   tests the packages ([Linux packages](#linux-packages)). Then `linux-release` checks that both
   file names carry the tag's version, checks their checksums, and uploads
   `ovos-gui-visage_<version>_amd64.deb`, `ovos-gui-visage_<version>_arm64.deb` and their `.sha256`
   files to the release.

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

## Linux packages

`.github/workflows/linux_deb.yml` has two jobs:

1. `package`, once per architecture on a native runner (`ubuntu-latest` for amd64, `ubuntu-24.04-arm`
   for arm64), inside a `debian:bookworm` container. A build on Ubuntu 24.04 needs glibc 2.39 and does
   not start on Bookworm (glibc 2.36); a Bookworm build runs on both. The job clones Flutter at the tag
   in `FLUTTER_VERSION` (the release archives are x64 only), runs `flutter build linux --release` and
   `tool/package_deb.sh`, runs `lintian --fail-on error,warning`, and stops if any binary needs a glibc
   symbol newer than 2.36. It keeps the `.deb` and its `.sha256` as the artifact
   `ovos-gui-visage-deb-<arch>`.
2. `install`, for each architecture in clean `debian:bookworm` and `ubuntu:24.04` containers. It runs
   `tool/smoke_deb.sh`: `apt-get install ./<deb>`, a check that `/usr/bin/ovos-gui-visage` resolves and
   has no missing libraries, `desktop-file-validate`, 20 seconds of the app under Xvfb with
   `dbus-run-session` (any earlier exit fails), then `apt-get remove` and a check that nothing is left.

`tool/package_deb.sh [bundle]` takes a built bundle and makes the package with `dpkg-deb`, with the
version from `pubspec.yaml`:

| Path | What |
|---|---|
| `/opt/ovos-gui-visage/` | The Flutter bundle as built. The runner and the plugins are stripped, and the plugins lose the build machine's RUNPATH. |
| `/usr/bin/ovos-gui-visage` | A symlink to the binary. The engine finds its data through `/proc/self/exe`, so the symlink works. |
| `/usr/share/applications/net.oscillatelabs.ovosGuiVisage.desktop` | The launcher, `Exec=ovos-gui-visage`. |
| `/usr/share/icons/hicolor/<size>/apps/net.oscillatelabs.ovosGuiVisage.png` | The icons from `linux/icons/hicolor`. |
| `/usr/share/ovos-gui-visage/net.oscillatelabs.ovosGuiVisage-kiosk.desktop` | The kiosk autostart entry, for the user to copy to `~/.config/autostart`. The package does not turn it on. |
| `/usr/share/doc/ovos-gui-visage/`, `/usr/share/lintian/overrides/` | `copyright`, `changelog.gz` and `linux/debian/lintian-overrides`. |

`Depends` comes from `dpkg-shlibdeps` over every ELF file in the bundle. It includes GTK 3,
`libayatana-appindicator3-1` and glibc 2.34 or newer. `libegl1` and `libgles2` are added by hand,
because libepoxy loads them with `dlopen` and shlibdeps cannot see them. Without them the app aborts
at start. On Ubuntu 24.04, the time_t packages (`libgtk-3-0t64` and others) provide the Bookworm
names, so one package fits both. There are no maintainer scripts: the file triggers of
`hicolor-icon-theme` and `desktop-file-utils` refresh the icon cache and the desktop database.

Every lintian override in `linux/debian/lintian-overrides` has its reason beside it: the bundle in
`/opt`, the engine's own freetype and libjpeg, the AOT snapshot `libapp.so` with no `NEEDED`
entries, the web fonts of the face picker page, and no man page.

A dry run on any branch: a pull request that touches `linux/`, `pubspec.*`, the two scripts or the
workflow runs `Linux packages` by itself. On `main`, run it by hand (`workflow_dispatch`, with an
optional `ref`). GitHub dispatches only workflows that are on the default branch, so before this
workflow is merged, the pull request run is the dry run. The packages are artifacts of the run. To
make one locally, in a `debian:bookworm` container with the build tools of the `package` job:

```bash
flutter build linux --release
just linux-deb            # or: tool/package_deb.sh
lintian --fail-on error,warning build/release/*.deb
tool/smoke_deb.sh build/release/ovos-gui-visage_<version>_<arch>.deb   # root, in a throwaway container
```

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

5. Check the image on both platforms:

   ```bash
   docker buildx imagetools inspect ghcr.io/oscillatelabsllc/ovos-gui-visage:<version>   # linux/amd64 and linux/arm64
   ```

   The first push creates the package as private. Once, under the organisation's Packages, open
   `ovos-gui-visage`, set its visibility to public, and check that it is linked to this repository.

6. Check the Linux packages on the release page, then on a Debian or Ubuntu machine:

   ```bash
   curl -LO https://github.com/OscillateLabsLLC/ovos-gui-visage/releases/download/v<version>/ovos-gui-visage_<version>_arm64.deb
   curl -LO https://github.com/OscillateLabsLLC/ovos-gui-visage/releases/download/v<version>/ovos-gui-visage_<version>_arm64.deb.sha256
   sha256sum -c ovos-gui-visage_<version>_arm64.deb.sha256
   sudo apt install ./ovos-gui-visage_<version>_arm64.deb
   ```
