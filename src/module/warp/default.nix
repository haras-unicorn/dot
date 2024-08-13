{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = with pkgs; [
        (warp-terminal.override { waylandSupport = true; })
      ];
    };
  };
}
