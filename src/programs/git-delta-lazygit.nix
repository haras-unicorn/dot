{ pkgs, ... }:

{
  homeManagerModule = {
    dot.shell.aliases = {
      bruh = "${pkgs.lazygit}/bin/lazygit";
      bru = "${pkgs.gitui}/bin/gitui";
    };

    programs.delta.enable = true;
    programs.delta.enableGitIntegration = true;

    programs.git.enable = true;
    programs.git.attributes = [ "* text=auto eof=lf" ];
    programs.git.settings = {
      interactive.singleKey = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.default = "upstream";
      push.followTags = true;
      rerere.enabled = true;
      color.ui = "auto";
      fetch.prune = true;
    };

    programs.lazygit.enable = true;
    programs.lazygit.settings = {
      notARepository = "quit";
      promptToReturnFromSubprocess = false;
      gui = {
        filterMode = "fuzzy";
        showIcons = true;
        paging = {
          colorArg = "always";
          pager = "${pkgs.delta}/bin/delta --paging=never";
        };
      };
      os = {
        suspend = true;
      };
    };

    programs.gitui.enable = true;
  };
}
