{}:

{
  home.shellAliases = {
    lg = "lazygit";
  };

  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    notARepository = "quit";
    promptToReturnFromSubprocess = false;
    gui = {
      showIcons = true;
    };
  };
}
