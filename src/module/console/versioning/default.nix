{ pkgs, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        bruh = "${pkgs.lazygit}/bin/lazygit";
      };
    };
  };

  home = {
    home.packages = [
      pkgs.delta
    ];

    programs.git.enable = true;
    programs.git.delta.enable = true;
    programs.git.attributes = [ "* text=auto eof=lf" ];
    programs.git.extraConfig = {
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
          pager = "${pkgs.delta}/bin/delta --dark --paging=never";
        };
      };
      os = {
        suspend = true;
      };
    };
  };
}
