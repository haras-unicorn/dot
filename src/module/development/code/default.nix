{ self
, pkgs
, config
, lib
, nix-vscode-extensions
, ...
}:

# TODO: extensions in projects

let
  package = self.lib.electron.wrap pkgs pkgs.vscodium "codium";
in
{
  shared = lib.mkIf config.dot.hardware.monitor.enable {
    dot = {
      shell.aliases = {
        code = "${package}/bin/codium";
      };
    };
  };

  home = lib.mkIf config.dot.hardware.monitor.enable {
    nixpkgs.overlays = [
      nix-vscode-extensions.overlays.default
    ];

    programs.vscode.enable = true;
    programs.vscode.package = package;

    programs.vscode.keybindings = (builtins.fromJSON (builtins.readFile ./keybindings.json));
    programs.vscode.userSettings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
      "editor.fontFamily" = ''"${config.dot.font.nerd.name}"'';
      "debug.console.fontFamily" = ''"${config.dot.font.nerd.name}"'';
      "terminal.integrated.fontFamily" = ''"${config.dot.font.nerd.name}"'';
      "editor.fontSize" = config.dot.font.size.medium + 1;
      "debug.console.fontSize" = config.dot.font.size.small + 1;
      "terminal.integrated.fontSize" = config.dot.font.size.small + 1;
      "terminal.external.linuxExec" = "${config.dot.terminal.package}/bin/${config.dot.terminal.bin}";
      "terminal.integrated.profiles.linux" = {
        "${config.dot.shell.bin}" = {
          "path" = "${config.dot.shell.package}/bin/${config.dot.shell.bin}";
        };
        "bash" = {
          "path" = "${pkgs.bashInteractive}/bin/bash";
          "icon" = "terminal-bash";
        };
      };
      "terminal.integrated.defaultProfile.linux" = "${config.dot.shell.bin}";
      "terminal.integrated.automationProfile.linux" = {
        "path" = "${pkgs.bashInteractive}/bin/bash";
      };
      "workbench.colorTheme" = "Atom One Dark";
      "workbench.iconTheme" = "material-icon-theme";
    };

    programs.vscode.enableExtensionUpdateCheck = false;
    programs.vscode.enableUpdateCheck = false;
    programs.vscode.mutableExtensionsDir = false;
    programs.vscode.extensions = with pkgs.vscode-marketplace; [
      # keybindings
      # jasew.vscode-helix-emulation
      vscodevim.vim

      # ui
      usernamehw.errorlens
      wayou.vscode-todo-highlight
      naumovs.color-highlight

      # theme
      akamud.vscode-theme-onedark
      pkief.material-icon-theme

      # ai
      supermaven.supermaven
      continue.continue

      # nix
      bbenoist.nix

      # rust
      pkgs.vscode-extensions.vadimcn.vscode-lldb
      rust-lang.rust-analyzer

      # csharp
      pkgs.vscode-extensions.ms-dotnettools.csdevkit
      ms-dotnettools.vscode-dotnet-runtime
      pkgs.vscode-extensions.ms-dotnettools.csharp
      selcukermaya.se-csproj-extensions

      # python
      charliermarsh.ruff
      eeyore.yapf
      ms-pyright.pyright
      ms-python.debugpy
      ms-python.python
      # ms-toolsai.jupyter

      # shell
      bmalehorn.shell-syntax
      foxundermoon.shell-format
      ms-vscode.powershell
      thenuprojectcontributors.vscode-nushell-lang
      timonwong.shellcheck

      # markdown
      shd101wyy.markdown-preview-enhanced
      davidanson.vscode-markdownlint
      unifiedjs.vscode-mdx
      esbenp.prettier-vscode

      # web
      # gamunu.vscode-yarn
      # arcanis.vscode-zipfs
      # dbaeumer.vscode-eslint
      # graphql.vscode-graphql
      # graphql.vscode-graphql-syntax
      # meganrogge.template-string-converter
      # sissel.shopify-liquid
      # styled-components.vscode-styled-components
      # stylelint.vscode-stylelint

      # content
      ctcuff.font-preview
      davidwang.ini-for-vscode
      codezombiech.gitignore
      editorconfig.editorconfig
      emilast.logfilehighlighter
      jock.svg
      ms-vscode.hexeditor
      redhat.vscode-yaml
      skellock.just
      tamasfe.even-better-toml
      tomoki1207.pdf

      # spelling
      streetsidesoftware.code-spell-checker
      streetsidesoftware.code-spell-checker-croatian
    ];
  };
}