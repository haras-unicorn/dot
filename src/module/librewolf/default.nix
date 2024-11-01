{ config, lib, pkgs, ... }:

# TODO: with extensions
# TODO: possibly like chromium - use firefox config with librewolf package

let
  cfg = config.dot.browser;
in
{
  home = {
    programs.librewolf.enable = true;
    programs.librewolf.package =
      (p: yes: no: lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ])
        (cfg.bin == "librewolf")
        cfg.package
        pkgs.librewolf;
  };
}
