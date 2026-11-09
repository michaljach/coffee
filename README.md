# Coffee

A tiny macOS menu bar app that keeps your Mac awake — even with the lid closed.

- **Left-click** the cup: toggle `pmset -a disablesleep 1/0` (filled cup = awake)
- **Right-click**: state + Quit

## Install

```sh
brew trust --cask michaljach/tap/coffee   # Homebrew 7+ requires trusting third-party casks
brew install --cask michaljach/tap/coffee
```

Homebrew asks for your password once: it installs a sudoers rule (`/etc/sudoers.d/coffee`)
that lets you run only `pmset -a disablesleep 0|1` without a password, so toggling never prompts.
`brew uninstall --cask coffee` re-enables sleep and removes the rule.

## Build from source

```sh
./build.sh install        # build, install to /Applications/Coffee.app, relaunch
./install-sudoers.sh      # optional: toggle without a password prompt
./build.sh release        # zip for a GitHub release / the cask
```

Note: quitting the app does not re-enable sleep — toggle it off first.
