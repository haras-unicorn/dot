{ pkgs, lib, config, ... }:

let
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  home = lib.mkIf (hasKeyboard) {
    home.packages = [
      pkgs.vim
    ];
  };
}
