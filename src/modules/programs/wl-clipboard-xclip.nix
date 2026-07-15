# TODO: ensure -t and -l behavior for commands

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
        name = "copy-wlx";
        runtimeInputs = [ wl-clipboard ];
        text = ''
          wl-copy --paste-once "$@"
        '';
      };

      pasteWayland = pkgs.writeShellApplication {
        name = "paste-wlx";
        runtimeInputs = [ wl-clipboard ];
        text = ''
          wl-paste "$@" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };

      copyXServer = pkgs.writeShellApplication {
        name = "copy-wlx";
        runtimeInputs = [ xclip ];
        text = ''
          cat | xclip -sel clip "$@"
        '';
      };

      pasteXServer = pkgs.writeShellApplication {
        name = "paste-wlx";
        runtimeInputs = [ xclip ];
        text = ''
          xclip -o -sel clip "$@" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };
    in
    lib.mkMerge [
      (lib.mkIf (hardware.graphics && hardware.wayland) {
        dot.processing = {
          sources = {
            wl-clipboard = {
              note = "Paste contents of the clipboard";
              tags = [
                "clipboard"
                "paste"
              ];
              output = "detect";
              package = pasteWayland;
            };
          };
          sinks = {
            wl-clipboard = {
              note = "Copy contents to the clipboard";
              tags = [
                "clipboard"
                "copy"
              ];
              inputs = "any";
              package = copyWayland;
            };
          };
        };

        dot.commands.copy = copyWayland;
        dot.commands.paste = pasteWayland;

        home.packages = [
          wl-clipboard
          xclip
        ];
      })
      (lib.mkIf (hardware.graphics && !hardware.wayland) {
        dot.processing = {
          sources = {
            xclip = {
              note = "Paste contents of the clipboard";
              tags = [
                "clipboard"
                "paste"
              ];
              output = "detect";
              package = pasteXServer;
            };
          };
          sinks = {
            xclip = {
              note = "Copy contents to the clipboard";
              tags = [
                "clipboard"
                "copy"
              ];
              inputs = "any";
              package = copyXServer;
            };
          };
        };

        dot.commands.copy = copyXServer;
        dot.commands.paste = pasteXServer;

        home.packages = [
          xclip
        ];
      })
    ];
}
