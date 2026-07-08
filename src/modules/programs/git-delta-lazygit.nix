{
  machines.homeModules.git-delta-lazygit =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
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
      programs.lazygit.shellWrapperName = "lg";
      programs.lazygit.settings = {
        notARepository = "quit";
        promptToReturnFromSubprocess = false;
        gui = {
          filterMode = "fuzzy";
          showIcons = true;
          paging = {
            colorArg = "always";
            pager = "${lib.getExe pkgs.delta} --paging=never";
          };
        };
        os = {
          suspend = true;
        };
      };
    };
}
