{
  pkgs,
  lib,
  config,
  ...
}:

let
  copyWayland = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [
      pkgs.wl-clipboard
      pkgs.xclip
      pkgs.coreutils
    ];
    text = ''
      tmpfile="$(mktemp)"
      trap 'rm -f "$tmpfile"' EXIT

      cat > "$tmpfile"

      wl-copy "$@" < "$tmpfile"
      xclip -sel clipboard "$@" < "$tmpfile"
    '';
  };

  pasteWayland = pkgs.writeShellApplication {
    name = "paste";
    runtimeInputs = [
      pkgs.wl-clipboard
      pkgs.coreutils
    ];
    text = ''
      wl-paste "$@"
    '';
  };

  copyXServer = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [
      pkgs.xclip
      pkgs.coreutils
    ];
    text = ''
      xclip -sel clip "$@"
    '';
  };

  pasteXServer = pkgs.writeShellApplication {
    name = "paste";
    runtimeInputs = [
      pkgs.xclip
      pkgs.coreutils
    ];
    text = ''
      xclip -o -sel clip "$@"
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  homeManagerModule = lib.mkMerge [
    (lib.mkIf (hasMonitor && hasWayland) {
      dot.shell.copy = copyWayland;
      dot.shell.paste = pasteWayland;
    })
    (lib.mkIf (hasMonitor && !hasWayland) {
      dot.shell.copy = copyXServer;
      dot.shell.paste = pasteXServer;
    })
  ];
}
