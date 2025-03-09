{ ... }:

# TODO: configure

{
  branch.homeManagerModule.homeManagerModule = {
    programs.yazi.enable = true;

    programs.yazi.settings = builtins.fromTOML ''
      [manager]
      show_hidden = true
    '';
  };
}
