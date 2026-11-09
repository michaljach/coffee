#!/bin/zsh
# Optional: allow toggling without a password prompt (only for pmset disablesleep).
set -e
F=/etc/sudoers.d/coffee
echo "$USER ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1" | sudo tee $F >/dev/null
sudo chmod 440 $F
sudo visudo -cf $F
