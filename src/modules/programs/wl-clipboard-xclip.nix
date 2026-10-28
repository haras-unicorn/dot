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
        dot.commands.copy = pkgs.harasPackages.copy-wl;
        dot.commands.paste = pkgs.harasPackages.paste-wl;

        home.packages = [
          wl-clipboard
          xclip
        ];
      })
      (lib.mkIf (hardware.graphics && !hardware.wayland) {
        dot.commands.copy = pkgs.harasPackages.copy-x;
        dot.commands.paste = pkgs.harasPackages.paste-x;

        home.packages = [
          xclip
        ];
      })
    ];
}
