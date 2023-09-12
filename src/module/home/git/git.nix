{ pkgs, ... }:
{
  home.packages = with pkgs; [
    meld
    delta
  ];

  # home.shellAliases = {
  #   bruh = "git";
  #   lg = "lazygit";
  # };
  programs.nushell.extraEnv = ''
    alias rawdog = git;
    alias bruh = lazygit;
  '';

  programs.git.enable = true;
  programs.git.delta.enable = true;
  programs.git.attributes = [ "* text=auto eof=lf" ];
  programs.git.lfs.enable = true;
  programs.git.signing.signByDefault = true;
  # TODO: figure out smooth gpg across all platforms once and for all
  programs.git.signing.key = "8A2BB645A7A84277A9D6BC41987A64C9A6B34535";
  programs.git.userEmail = "social@hrvojej.anonaddy.me";
  programs.git.userName = "Hrvoje Jurić";
  programs.git.extraConfig = {
    interactive.singleKey = true;
    init.defaultBranch = "main";
    pull.rebase = true;
    push.default = "upstream";
    push.followTags = true;
    rerere.enabled = true;
    merge.tool = "meld";
    "mergetool \"meld\"".cmd = ''meld "$LOCAL" "$MERGED" "$REMOTE" --output "$MERGED"'';
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
        pager = "delta --dark --paging=never";
      };
    };
  };
}
