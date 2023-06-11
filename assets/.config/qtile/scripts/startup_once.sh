#!/usr/bin/env bash

function run {
  if [[ ! "$(pgrep "$1")" ]]; then
    "$@"&
  fi
}

run lxsession
run pcmanfm -d
run dunst
run nm-applet
run flameshot
run redshift-gtk
