# Overfold

A small menu bar app that hides the icons you don't need. No settings window, nothing to configure: you arrange icons with ⌘-drag and Overfold keeps them out of the way.

Requires macOS 14 or later.

## Install

Download the latest `Overfold-<version>.dmg` from [Releases](https://github.com/howells/overfold/releases), open it and drag Overfold to Applications.

## Use

On first launch Overfold shows everything, with two lines next to its arrow. Hold ⌘ and drag icons around them:

- **Right of the grey line:** always shown.
- **Grey to blue:** shown when you click the arrow, or press ⌃⌥O.
- **Left of the blue line:** shown only when you ⌥-click the arrow.

Click the arrow when you're done. Revealed icons hide again when you click elsewhere or after 15 seconds, but never while a menu is open. ⌥-click the arrow to see the lines and rearrange. Right-click it for Open at login and Quit.

Overfold needs no permissions.

## Build

```sh
./scripts/install.sh   # build, ad-hoc sign and install to /Applications
./scripts/release.sh   # build, sign with Developer ID, notarise, and make a DMG
```

`release.sh` needs a Developer ID Application certificate and a `notarytool` keychain profile named `overfold`.
