{ pkgs, lib, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        rawdog = "${pkgs.git}/bin/git";
        bruh = "${pkgs.lazygit}/bin/lazygit";
      };
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      meld
      delta
    ];

    programs.git.enable = true;
    programs.git.delta.enable = true;
    programs.git.attributes = [ "* text=auto eof=lf" ];
    programs.git.lfs.enable = true;
    programs.git.extraConfig = {
      interactive.singleKey = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.default = "upstream";
      push.followTags = true;
      rerere.enabled = true;
      merge.tool = "meld";
      "mergetool \"meld\"".cmd = ''${pkgs.meld}/bin/meld "$LOCAL" "$MERGED" "$REMOTE" --output "$MERGED"'';
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
        edit = lib.mkDefault (pkgs.vim + "/bin/vim -- {{filename}}");
        editAtLine = lib.mkDefault (pkgs.vim + "/bin/vim +{{line}} -- {{filename}}");
        editAtLineAndWait = lib.mkDefault (pkgs.vim + "/bin/vim +{{line}} -- {{filename}}");
        openDirInEditor = lib.mkDefault (pkgs.vim + "/bin/vim -- {{dir}}");
        suspend = lib.mkDefault true;
      };
    };
  };
}
