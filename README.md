<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/cup-on-dark.png">
    <img src="assets/cup-on-light.png" width="96" alt="Coffee icon">
  </picture>
</p>

<h1 align="center">Coffee</h1>

<p align="center">
  A tiny macOS menu bar app that keeps your Mac awake — <b>even with the lid closed</b>.<br>
  One click on, one click off. No windows, no settings, no Dock icon.
</p>

<p align="center">
  <a href="https://github.com/michaljach/coffee/releases/latest"><img src="https://img.shields.io/github/v/release/michaljach/coffee?label=release" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-12%2B-black?logo=apple" alt="macOS 12+">
  <img src="https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-black" alt="Universal binary">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-black" alt="MIT license"></a>
</p>

---

## Install

```sh
brew trust --cask michaljach/tap/coffee   # Homebrew 7+ requires trusting third-party casks
brew install --cask michaljach/tap/coffee
```

Homebrew asks for your password **once**, during install. After that, toggling never prompts.

## Usage

| Icon | State |
|:---:|---|
| <picture><source media="(prefers-color-scheme: dark)" srcset="assets/cup-off-dark.png"><img src="assets/cup-off-light.png" width="24" alt="Empty cup"></picture> | **Off** — your Mac sleeps normally |
| <picture><source media="(prefers-color-scheme: dark)" srcset="assets/cup-on-dark.png"><img src="assets/cup-on-light.png" width="24" alt="Full cup"></picture> | **On** — sleep is disabled, including when you close the lid |

- **Click** the cup to toggle.
- **Right-click** (or ⌃-click) for the current state and **Quit**.

To start Coffee automatically, add it in **System Settings → General → Login Items**.

## How it works

Most keep-awake tools (including `caffeinate`) hold a power assertion, which macOS ignores when you
close the lid (unless an external display is connected). Coffee instead flips the system-wide
setting directly:

```sh
pmset -a disablesleep 1   # on
pmset -a disablesleep 0   # off
```

That setting needs root, so the Homebrew install adds a narrowly scoped sudoers rule at
`/etc/sudoers.d/coffee`. It lets your user run **only** those two exact commands without a password:

```
you ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

If the rule is missing, Coffee falls back to the standard macOS admin password prompt.

On launch, Coffee reads the current state from `pmset -g`, so the icon is always accurate.

> [!WARNING]
> Quitting Coffee does **not** turn sleep back on — the setting is system-wide and persists.
> Toggle it off before quitting. A MacBook kept awake with the lid closed in a bag can get hot.

## Uninstall

```sh
brew uninstall --cask coffee
```

This quits the app, re-enables sleep, and removes the sudoers rule.

## Build from source

Requires the Xcode Command Line Tools. The whole app is a single file, [`main.swift`](main.swift).

```sh
./build.sh                # build Coffee.app (universal)
./build.sh install        # build, install to /Applications, relaunch
./install-sudoers.sh      # optional: passwordless toggling without Homebrew
./build.sh release        # zip for a GitHub release
```

## License

[MIT](LICENSE) © Michal Jach
