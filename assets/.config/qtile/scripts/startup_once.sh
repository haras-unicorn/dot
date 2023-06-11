#!/usr/bin/env bash

# check if program exists before running it
function run {
  if [[ ! "$(pgrep "$1")" ]]; then
    "$@"&
  fi
}

# X Session
lxsession &

# GVFS/PCManFM
run pcmanfm -d &

# Set numlock on
run numlockx on &

# Compositor
run picom --experimental-backends &

# Notifications
run dunst &

# TODO: setup pywal colors
#pywal-colors.py

# TODO: setup animated background?

# Systray
# NOTE: Don't use services for these!
# https://github.com/jonls/redshift/issues/265#issuecomment-3382457480
run nm-applet &
run pamac-tray &
run flameshot &
run redshift-gtk &
run fcitx5-qt &
run evolution --component=calendar &
