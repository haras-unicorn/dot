source "$HOME/.config/shell/profile.sh";

if [[ -n "$DESKTOP_SESSION" ]]; then
  eval "$(gnome-keyring-daemon --start)";
  export SSH_AUTH_SOCK;
fi;

export LOADED_ZPROFILE=1;
