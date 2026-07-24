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
