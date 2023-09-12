{ pkgs, ... }:

let
  poetryPylsp = pkgs.writeScriptBin "poetry-pylsp"
    ''
      #!${pkgs.stdenv.shell}
      set -eo pipefail

      source "$("${pkgs.poetry}/bin/poetry" env info --path)/bin/activate"

      "${pkgs.python310Packages.python-lsp-server}/bin/pylsp" "$@"
    '';

  poetryPyrightLangserver = pkgs.writeScriptBin "poetry-pyright-langserver"
    ''
      #!${pkgs.stdenv.shell}
      set -eo pipefail

      source "$("${pkgs.poetry}/bin/poetry" env info --path)/bin/activate"

      "${pkgs.nodePackages.pyright}/bin/pyright-langserver" "$@"
    '';

  poetryRuffLsp = pkgs.writeScriptBin "poetry-ruff-lsp"
    ''
      #!${pkgs.stdenv.shell}
      set -eo pipefail

      source "$("${pkgs.poetry}/bin/poetry" env info --path)/bin/activate"

      "${pkgs.python310Packages.ruff-lsp}/bin/ruff-lsp" "$@"
    '';

  poetryPython = pkgs.writeScriptBin "poetry-python"
    ''
      #!${pkgs.stdenv.shell}
      set -eo pipefail

      "${pkgs.poetry}/bin/poetry" run python "$@"
    '';
in
{
  nixpkgs.overlays = [
    (final: prev: {
      nodejs = prev.nodejs_20;
    })
  ];
  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
    direnv
    nix-direnv
    (poetry.override { python3 = python310; })
    ruff
    nodePackages.pyright
    (python310.withPackages
      (pythonPackages: with pythonPackages; [
        python-lsp-server
        ruff-lsp
        python-lsp-ruff
        mypy
        pylsp-mypy
        pylsp-rope
        yapf
      ]))
    poetryPylsp
    poetryPyrightLangserver
    poetryRuffLsp
    poetryPython
    dotnet-sdk_7
    omnisharp-roslyn
    nodejs_20
    nodePackages.bash-language-server
    nodePackages.yaml-language-server
    nodePackages.dockerfile-language-server-nodejs
    cargo
    llvmPackages.clangNoLibcxx
    llvmPackages.lldb
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    shfmt
    marksman
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = VISUAL, hx
    env = EDITOR, hx
  '';

  programs.nushell.extraEnv = ''
    $env.VISUAL = hx;
    $env.EDITOR = hx;
    
    alias sis = hx;
  '';

  programs.helix.enable = true;
  programs.helix.languages = {
    language = [
      {
        name = "nix";
        auto-format = true;
        formatter = { command = "nixpkgs-fmt"; };
      }
      {
        name = "bash";
        auto-format = true;
        formatter = { command = "${pkgs.shfmt}/bin/shfmt"; };
      }
      {
        name = "python";
        auto-format = true;
        formatter = { command = "${pkgs.yapf}/bin/yapf"; };

        # NOTE: can't get it to work with ruff
        # language-server = { command = "${poetryPylsp}/bin/poetry-pylsp"; };
        # config.pylsp.plugins = {
        #   rope = { enabled = true; };
        #   ruff = {
        #     enabled = true;
        #     executable = "${pkgs.ruff}/bin/ruff";
        #   };
        #   mypy = {
        #     enabled = true;
        #     live_mode = false;
        #     dmypy = true;
        #     strict = true;
        #   };
        #   yapf = { enabled = false; };
        #   flake8 = { enabled = false; };
        #   pylint = { enabled = false; };
        #   pycodestyle = { enabled = false; };
        #   pyflakes = { enabled = false; };
        #   mccabe = { enabled = false; };
        #   autopep8 = { enabled = false; };
        # };
        # NOTE: unreleased: https://github.com/helix-editor/helix/pull/2507 
        # language-servers = [
        #   {
        #     command = "${poetryPyrightLangserver}/bin/poetry-pyright-langserver";
        #     args = [ "--stdio" ];
        #   }
        #   { command = "${poetryRuffLsp}/bin/poetry-ruff-lsp"; }
        # ];
        # config = { };
        # NOTE: https://github.com/helix-editor/helix/discussions/5369
        language-server = {
          command = "${poetryPyrightLangserver}/bin/poetry-pyright-langserver";
          args = [ "--stdio" ];
        };
        config = { };
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
