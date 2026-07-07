{
  machines.homeModules.wl-clipboard-xclip =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      wl-clipboard = pkgs.wl-clipboard;
      xclip = pkgs.xclip;

      copyWayland = pkgs.writeShellApplication {
        name = "copy";
        runtimeInputs = [
          wl-clipboard
          xclip
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
        runtimeInputs = [ wl-clipboard ];
        text = ''
          wl-paste "$@"
        '';
      };

      copyXServer = pkgs.writeShellApplication {
        name = "copy";
        runtimeInputs = [ xclip ];
        text = ''
          xclip -sel clip "$@"
        '';
      };

      pasteXServer = pkgs.writeShellApplication {
        name = "paste";
        runtimeInputs = [ xclip ];
        text = ''
          xclip -o -sel clip "$@"
        '';
      };
    in
    lib.mkMerge [
      (lib.mkIf (hardware.graphics && hardware.wayland) {
        dot.programs.shell.copy = copyWayland;
        dot.programs.shell.paste = pasteWayland;
      })
      (lib.mkIf (hardware.graphics && !hardware.wayland) {
        dot.programs.shell.copy = copyXServer;
        dot.programs.shell.paste = pasteXServer;
      })
    ];
}
