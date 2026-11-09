# Coffee

A tiny macOS menu bar app that keeps your Mac awake — even with the lid closed.

- **Left-click** the cup: toggle `pmset -a disablesleep 1/0` (filled cup = awake)
- **Right-click**: state + Quit

## Build & install

```sh
./build.sh                # builds, installs to /Applications/Coffee.app, relaunches
./install-sudoers.sh      # optional: toggle without a password prompt
```

Note: quitting the app does not re-enable sleep — toggle it off first.
