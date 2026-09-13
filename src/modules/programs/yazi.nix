{
  self.homeModules.yazi.value = {
    programs.yazi.enable = true;
    programs.yazi.shellWrapperName = "yy";
    programs.yazi.settings = builtins.fromTOML ''
      [mgr]
      show_hidden = true
    '';
  };
}
