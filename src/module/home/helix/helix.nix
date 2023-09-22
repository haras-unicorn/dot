{ pkgs, ... }:

let
  # poetryPylsp = pkgs.writeShellApplication {
  #   name = "poetry-pylsp";
  #   runtimeInputs = [ pkgs.poetry pkgs.python310Packages.python-lsp-server ];
  #   text = ''
  #     # shellcheck disable=SC1091
  #     source "$(poetry env info --path)/bin/activate"
  #     pylsp "$@"
  #   '';
  # };

  poetryPyrightLangserver = pkgs.writeShellApplication {
    name = "poetry-pyright-langserver";
    runtimeInputs = [ pkgs.poetry pkgs.nodePackages.pyright ];
    text = ''
      # shellcheck disable=SC1091
      source "$(poetry env info --path)/bin/activate"
      pyright-langserver "$@"
    '';
  };

  # poetryRuffLsp = pkgs.writeShellApplication {
  #   name = "poetry-ruff-lsp";
  #   runtimeInputs = [ pkgs.poetry pkgs.python310Packages.ruff-lsp ];
  #   text = ''
  #     # shellcheck disable=SC1091
  #     source "$(poetry env info --path)/bin/activate"
  #     ruff-lsp "$@"
  #   '';
  # };

  poet = pkgs.writeShellApplication {
    name = "poet";
    runtimeInputs = [ pkgs.poetry ];
    text = ''
      poetry run python "$@"
    '';
  };

  csharpier =
    pkgs.buildDotnetGlobalTool {
      pname = "csharpier";
      nugetName = "CSharpier";
      version = "0.25.0";
      nugetSha256 = "5A2901D6ADA3D18260B9C6DFE2133C95D74B9EEF6AE0E5DC334C8454D1477DF4";
      meta = with pkgs.lib; {
        homepage = "https://github.com/belav/csharpier";
        changelog = "https://github.com/belav/csharpier/blob/main/CHANGELOG.md";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    };
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
    poet
    dotnet-sdk_7
    omnisharp-roslyn
    netcoredbg
    csharpier
    nodejs_20
    bun
    nodePackages.yarn
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
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
    cargo-edit
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
      {
        name = "c-sharp";
        auto-format = true;
        formatter = { command = "${csharpier}/bin/csharpier"; };
        language-server = { command = "omnisharp"; args = [ "-lsp" ]; timeout = 10000; };
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
          "diagnostics"
          "workspace-diagnostics"
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
