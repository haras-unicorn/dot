{ ... }:

{
  self.overlays.overlays.clipboard.value = final: _prev: {
    copy-wl = final.writeShellApplication {
      name = "copy-wl";
      runtimeInputs = [
        final.wl-clipboard
        final.xclip
      ];
      text = ''
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT
        cat > "$tmp"
        wl-copy "$@" < "$tmp"
        xclip -sel clip "$@" < "$tmp"
      '';
    };

    paste-wl = final.writeShellApplication {
      name = "paste-wl";
      runtimeInputs = [ final.wl-clipboard ];
      text = ''
        wl-paste "$@" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
      '';
    };

    copy-x = final.writeShellApplication {
      name = "copy-x";
      runtimeInputs = [ final.xclip ];
      text = ''
        cat | xclip -sel clip "$@"
        printf "copy done" 1>&2
      '';
    };

    paste-x = final.writeShellApplication {
      name = "paste-x";
      runtimeInputs = [ final.xclip ];
      text = ''
        xclip -o -sel clip "$@" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
      '';
    };
  };
}
