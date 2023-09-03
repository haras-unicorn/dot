{ pkgs, ... }:

{
  home.shellAliases = {
    lg = "lazygit";
  };

  home.packages = with pkgs; [
    delta
  ];

  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    notARepository = "quit";
    promptToReturnFromSubprocess = false;
    gui = {
      showIcons = true;
      paging = {
        colorArg = "always";
        pager = "delta --dark --paging=never";
      };
    };
  };
}
