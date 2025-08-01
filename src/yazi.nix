{ ... }:

# TODO: configure

{
  branch.homeManagerModule.homeManagerModule = {
    programs.yazi.enable = true;

    programs.yazi.settings = builtins.fromTOML ''
      [mgr]
      show_hidden = true
    '';
  };
}
