{ pkgs, config, ... }:

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
  programs.helix.settings = {
    theme = "wallpaper";
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
  programs.helix.themes.everforest_transparent = {
    inherits = "everforest_dark";

    "ui.background" = { };
    "ui.statusline" = { fg = "fg"; };
  };
  programs.lulezojne.config.plop = [
    {
      template = ''
        "type" = "yellow"
        "constant" = "fg"
        "constant.builtin" = { fg = "purple", modifiers = ["italic"] }
        "constant.builtin.boolean" = "purple"
        "constant.numeric" = "purple"
        "constant.character.escape" = "green"
        "string" = "aqua"
        "string.regexp" = "green"
        "string.special" = "yellow"
        "comment" = { fg = "grey1", modifiers = ["italic"] }
        "variable" = "fg"
        "variable.builtin" = { fg = "purple", modifiers = ["italic"] }
        "variable.parameter" = "fg"
        "variable.other.member" = "blue"
        "label" = "orange"
        "punctuation" = "grey2"
        "punctuation.delimiter" = "grey1"
        "punctuation.bracket" = "fg"
        "punctuation.special" = "blue"
        "keyword" = "red"
        "keyword.operator" = "orange"
        "keyword.directive" = "purple"
        "keyword.storage" = "red"
        "operator" = "orange"
        "function" = "green"
        "function.macro" = "green"
        "tag" = "orange"
        "namespace" = { fg = "yellow", modifiers = ["italic"] }
        "attribute" = { fg = "purple", modifiers = ["italic"] }
        "constructor" = "green"
        "module" = "yellow"
        "special" = "blue"

        "markup.heading.marker" = "grey1"
        "markup.heading.1" = { fg = "red", modifiers = ["bold"] }
        "markup.heading.2" = { fg = "orange", modifiers = ["bold"] }
        "markup.heading.3" = { fg = "yellow", modifiers = ["bold"] }
        "markup.heading.4" = { fg = "green", modifiers = ["bold"] }
        "markup.heading.5" = { fg = "blue", modifiers = ["bold"] }
        "markup.heading.6" = { fg = "purple", modifiers = ["bold"] }
        "markup.list" = "red"
        "markup.bold" = { modifiers = ["bold"] }
        "markup.italic" = { modifiers = ["italic"] }
        "markup.strikethrough" = { modifiers = ["crossed_out"] }
        "markup.link.url" = { fg = "blue", underline = { style = "line" } }
        "markup.link.label" = "orange"
        "markup.link.text" = "purple"
        "markup.quote" = "grey1"
        "markup.raw.inline" = "green"
        "markup.raw.block" = "aqua"

        "diff.plus" = "green"
        "diff.delta" = "blue"
        "diff.minus" = "red"

        "ui.background" = { }
        "ui.background.separator" = "bg_visual"
        "ui.cursor" = { fg = "bg1", bg = "grey2" }
        "ui.cursor.insert" = { fg = "bg0", bg = "grey1" }
        "ui.cursor.select" = { fg = "bg0", bg = "blue" }
        "ui.cursor.match" = { fg = "orange", bg = "bg_yellow" }
        "ui.cursor.primary" = { fg = "bg0", bg = "fg" }
        "ui.cursorline.primary" = { bg = "bg1" }
        "ui.cursorline.secondary" = { bg = "bg2" }
        "ui.selection" = { bg = "bg3" }
        "ui.linenr" = "grey0"
        "ui.linenr.selected" = "grey2"
        "ui.statusline" = { fg = "fg" }
        "ui.statusline.inactive" = { fg = "grey0", bg = "bg1" }
        "ui.statusline.normal" = { fg = "bg0", bg = "statusline1", modifiers = [ "bold" ] }
        "ui.statusline.insert" = { fg = "bg0", bg = "statusline2", modifiers = [ "bold" ] }
        "ui.statusline.select" = { fg = "bg0", bg = "blue", modifiers = ["bold"] }
        "ui.bufferline" = { fg = "grey2", bg = "bg3" }
        "ui.bufferline.active" = { fg = "bg0", bg = "statusline1", modifiers = [ "bold" ] }
        "ui.popup" = { fg = "grey2", bg = "bg2" }
        "ui.window" = { fg = "bg4", bg = "bg_dim" }
        "ui.help" = { fg = "fg", bg = "bg2" }
        "ui.text" = "fg"
        "ui.text.focus" = "fg"
        "ui.menu" = { fg = "fg", bg = "bg3" }
        "ui.menu.selected" = { fg = "bg0", bg = "green" }
        "ui.virtual.ruler" = { bg = "bg3" }
        "ui.virtual.whitespace" = { fg = "bg4" }
        "ui.virtual.indent-guide" = { fg = "bg4" }
        "ui.virtual.inlay-hint" = { fg = "grey0" }
        "ui.virtual.wrap" = { fg = "grey0" }

        "hint" = "green"
        "info" = "blue"
        "warning" = "yellow"
        "error" = "red"

        "diagnostic.hint" = { underline = { color = "green", style = "curl" } }
        "diagnostic.info" = { underline = { color = "blue", style = "curl" } }
        "diagnostic.warning" = { underline = { color = "yellow", style = "curl" } }
        "diagnostic.error" = { underline = { color = "red", style = "curl" } }

        [palette]

        bg_dim = "#232a2e"
        bg0 = "#2d353b"
        bg1 = "#343f44"
        bg2 = "#3d484d"
        bg3 = "#475258"
        bg4 = "#4f585e"
        bg5 = "#56635f"
        bg_visual = "#543a48"
        bg_red = "#514045"
        bg_green = "#425047"
        bg_blue = "#3a515d"
        bg_yellow = "#4d4c43"

        fg = "{{ hex ansi.main.bright_white }}"

        red = "{{ hex ansi.main.bright_red }}"
        orange = "{{ hex ansi.main.yellow }}"
        yellow = "{{ hex ansi.main.bright_yellow }}"
        green = "{{ hex ansi.main.bright_green }}"
        aqua = "{{ hex ansi.main.bright_cyan }}"
        blue = "{{ hex ansi.main.bright_blue }}"
        purple = "{{ hex ansi.main.bright_magenta }}"

        grey0 = "{{ hex ansi.grayscale.8 }}"
        grey1 = "{{ hex ansi.grayscale.16 }}"
        grey2 = "{{ hex ansi.grayscale.24 }}"

        statusline1 = "#a7c080"
        statusline2 = "#d3c6aa"
        statusline3 = "#e67e80"
      '';
      "in" = "${config.xdg.configHome}/helix/themes/wallpaper.toml";
      "then" = {
        command = "pkill";
        args = [ "--signal" "SIGUSR1" "hx" ];
      };
    }
  ];
}
