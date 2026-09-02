# raulgg's Homebrew Tap

Homebrew tap for distributing my command-line tools and macOS apps.

## Install

Tap the repository once:

```sh
brew tap raulgg/tap
```

Or install a package directly:

```sh
# Formula
brew install raulgg/tap/FORMULA_NAME

# Cask
brew install --cask raulgg/tap/CASK_NAME
```

## Packages

### Formulae

- [`airpods-control`](https://github.com/raulgg/airpods-control) — Control
  AirPods listening mode and Conversation Awareness from the command line.
  Builds from source and requires Command Line Tools or Xcode.

### Casks

No casks yet.

## Formula updates

Published `airpods-control` releases dispatch the formula updater. It accepts
only the latest stable tag reachable from upstream `main` or the matching
`release/MAJOR.MINOR` maintenance branch. It rejects downgrades and checksum
changes for an existing version, then verifies two downloads of the source
archive before opening or updating one pull request. The pull request
auto-merges only after every required `brew test-bot` check passes. Maintainers
can replay a failed update from the Update airpods-control formula workflow by
entering the current latest stable tag.

## Update and uninstall

```sh
brew update
brew upgrade
brew uninstall FORMULA_NAME
brew uninstall --cask CASK_NAME
```

Run `brew info raulgg/tap/PACKAGE_NAME` for package-specific details.

This is a third-party tap. Review a package's formula or cask and its upstream
source before installation.
