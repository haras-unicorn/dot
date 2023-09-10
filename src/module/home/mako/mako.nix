{ ... }:

{
  services.mako.enable = true;
  services.mako.extraConfig = builtins.readFile ./config;
}
