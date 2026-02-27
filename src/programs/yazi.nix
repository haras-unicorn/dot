{ ... }:

# TODO: configure

{
  flake.homeModules.programs-yazi = {
    programs.yazi.enable = true;

    programs.yazi.settings = builtins.fromTOML ''
      [mgr]
      show_hidden = true
    '';
  };
}
