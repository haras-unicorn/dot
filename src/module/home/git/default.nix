{ pkgs, ... }:
{
  home.shared = {
    home.packages = with pkgs; [
      meld
      delta
    ];

    shell.aliases = {
      rawdog = "${pkgs.git}/bin/git";
      bruh = "${pkgs.lazygit}/bin/lazygit";
    };

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
    };

    programs.lazygit.enable = true;
    programs.lazygit.settings = {
      notARepository = "quit";
      promptToReturnFromSubprocess = false;
      gui = {
        showIcons = true;
        paging = {
          colorArg = "always";
          pager = "${pkgs.delta}/bin/delta --dark --paging=never";
        };
      };
    };
  };
}
