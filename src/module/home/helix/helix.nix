{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
    direnv
    nix-direnv
    # python311
    # python311Packages.python-lsp-server
    # python311Packages.black
    dotnet-sdk_7
    omnisharp-roslyn
    nodejs_20
    nodePackages.bash-language-server
    nodePackages.yaml-language-server
    nodePackages.dockerfile-language-server-nodejs
    rustc
    cargo
    marksman
  ];

  # home.sessionVariables = {
  #   VISUAL = "hx";
  #   EDITOR = "hx";
  # };
  # home.shellAliases = {
  #   sis = "hx";
  # };
  programs.nushell.extraEnv = ''
    $env.VISUAL = "hx";
    $env.EDITOR = "hx";
    alias sis = hx;
  '';

  programs.helix.enable = true;
  programs.helix.languages = {
    language = [
      {
        name = "python";
        auto-format = true;
        formatter = { command = "black"; };
      }
      {
        name = "nix";
        auto-format = true;
        formatter = { command = "nixpkgs-fmt"; };
      }
    ];
  };
  programs.helix.settings = {
    theme = "transparent";
    editor = {
      true-color = true;
      scrolloff = 999;
      auto-save = true;
      rulers = [ ];
      gutters = [ "diagnostics" "spacer" "diff" ];
      file-picker = {
        hidden = false;
      };
      statusline = {
        left = [
          "spinner"
          "workspace-diagnostics"
          "diagnostics"
        ];
        center = [ ];
        right = [
          "file-base-name"
          "position"
        ];
      };
      lsp = {
        display-inlay-hints = true;
      };
      cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
  };
  programs.helix.themes.transparent = {
    inherits = "everforest_dark";

    "ui.background" = { };
    "ui.statusline" = { fg = "fg"; };
  };
}
