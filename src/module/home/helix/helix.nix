{ pkgs, config, ... }:

# TODO: remove language configs and move to repos

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

  # csharpier =
  #   pkgs.buildDotnetGlobalTool {
  #     pname = "dotnet-csharpier";
  #     nugetName = "CSharpier";
  #     version = "0.25.0";
  #     nugetSha256 = "sha256-7yRDI7vdLTXv0XuUHKUdsIJsqzmw3cidWjmbZ5g5Vvg=";
  #     dotnet-sdk = pkgs.dotnetCorePackages.sdk_6_0;
  #     dotnet-runtime = pkgs.dotnetCorePackages.sdk_6_0;
  #     meta = with pkgs.lib; {
  #       homepage = "https://github.com/belav/csharpier";
  #       changelog = "https://github.com/belav/csharpier/blob/main/CHANGELOG.md";
  #       license = licenses.mit;
  #       platforms = platforms.linux;
  #     };
  #   };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      nodejs = prev.nodejs_20;
      dotnet-sdk = prev.dotnet-sdk_7;
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
    dotnet-sdk
    omnisharp-roslyn
    netcoredbg
    # csharpier
    nodejs
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
    taplo
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = VISUAL, ${pkgs.helix}/bin/hx
    env = EDITOR, ${pkgs.helix}/bin/hx
  '';

  programs.nushell.environmentVariables = {
    VISUAL = "${pkgs.helix}/bin/hx";
    EDITOR = "${pkgs.helix}/bin/hx";
  };

  programs.nushell.shellAliases = {
    sis = "${pkgs.helix}/bin/hx";
  };

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
        # TODO: https://github.com/dotnet/sdk/issues/30546
        # auto-format = true;
        # formatter = { command = "${csharpier}/bin/dotnet-csharpier"; };
        language-server = { command = "${pkgs.omnisharp-roslyn}/bin/OmniSharp"; args = [ "-lsp" ]; timeout = 10000; };
      }
      {
        name = "toml";
        auto-format = true;
      }
    ];
  };
  programs.helix.settings = builtins.fromTOML (builtins.readFile ./settings.toml);

  programs.lulezojne.config.plop = [
    {
      template = builtins.readFile ./lulezojne.toml;
      "in" = "${config.xdg.configHome}/helix/themes/lulezojne.toml";
      "then" = {
        command = "pkill";
        args = [ "--signal" "SIGUSR1" "hx" ];
      };
    }
  ];
}
