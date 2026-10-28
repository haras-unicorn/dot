# TODO: ensure -t and -l behavior for commands

{
  self.homeModules.wl-clipboard-xclip.value =
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
              package = pkgs.harasPackages.paste-wl;
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
              package = pkgs.harasPackages.copy-wl;
            };
          };
        };

        dot.commands.copy = pkgs.harasPackages.copy-wl;
        dot.commands.paste = pkgs.harasPackages.paste-wl;

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
              package = pkgs.harasPackages.paste-x;
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
              package = pkgs.harasPackages.copy-x;
            };
          };
        };

        dot.commands.copy = pkgs.harasPackages.copy-x;
        dot.commands.paste = pkgs.harasPackages.paste-x;

        home.packages = [
          xclip
        ];
      })
    ];
}
