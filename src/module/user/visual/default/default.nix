{ pkgs
, self
, config
, lib
, nix-vscode-extensions
, ...
}:

# TODO: extensions in projects

let
  package = config.unstablePkgs.vscodium.override {
    commandLineArgs = self.lib.chromium.args;
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  home = lib.mkIf (hasMonitor && hasKeyboard) {
    nixpkgs.overlays = [
      nix-vscode-extensions.overlays.default
    ];

    programs.vscode.enable = true;
    programs.vscode.package = package;

    programs.vscode.keybindings = (builtins.fromJSON (builtins.readFile ./keybindings.json));
    programs.vscode.userSettings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
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
      "workbench.iconTheme" = "material-icon-theme";
    };

    programs.vscode.enableExtensionUpdateCheck = false;
    programs.vscode.enableUpdateCheck = false;
    programs.vscode.mutableExtensionsDir = false;
    programs.vscode.extensions = [
      # keybindings
      # jasew.vscode-helix-emulation
      pkgs.vscode-marketplace.vscodevim.vim

      # ui
      pkgs.vscode-marketplace.usernamehw.errorlens
      pkgs.vscode-marketplace.wayou.vscode-todo-highlight
      pkgs.vscode-marketplace.naumovs.color-highlight
      pkgs.vscode-marketplace.ast-grep.ast-grep-vscode

      # theme
      pkgs.vscode-marketplace.pkief.material-icon-theme

      # ai
      pkgs.vscode-marketplace.supermaven.supermaven
      # pkgs.vscode-marketplace.continue.continue

      # nix
      pkgs.vscode-marketplace.bbenoist.nix

      # rust
      pkgs.vscode-extensions.vadimcn.vscode-lldb
      pkgs.vscode-marketplace.rust-lang.rust-analyzer

      # csharp
      pkgs.vscode-marketplace.ms-dotnettools.vscode-dotnet-runtime
      pkgs.vscode-marketplace.selcukermaya.se-csproj-extensions
      (pkgs.open-vsx.muhammad-sammy.csharp.overrideAttrs (final: prev: { }))
      # pkgs.vscode-extensions.ms-dotnettools.csdevkit
      # pkgs.vscode-extensions.ms-dotnettools.csharp

      # python
      pkgs.vscode-marketplace.charliermarsh.ruff
      pkgs.vscode-marketplace.eeyore.yapf
      pkgs.vscode-marketplace.ms-pyright.pyright
      pkgs.vscode-marketplace.ms-python.debugpy
      pkgs.vscode-marketplace.ms-python.python
      # pkgs.vscode-marketplace.ms-toolsai.jupyter

      # shell
      pkgs.vscode-marketplace.bmalehorn.shell-syntax
      pkgs.vscode-marketplace.foxundermoon.shell-format
      pkgs.vscode-marketplace.ms-vscode.powershell
      pkgs.vscode-marketplace.thenuprojectcontributors.vscode-nushell-lang
      pkgs.vscode-marketplace.timonwong.shellcheck

      # markdown
      pkgs.vscode-marketplace.shd101wyy.markdown-preview-enhanced
      pkgs.vscode-marketplace.davidanson.vscode-markdownlint
      pkgs.vscode-marketplace.unifiedjs.vscode-mdx
      pkgs.vscode-marketplace.esbenp.prettier-vscode

      # web
      # pkgs.vscode-marketplace.gamunu.vscode-yarn
      # pkgs.vscode-marketplace.arcanis.vscode-zipfs
      # pkgs.vscode-marketplace.dbaeumer.vscode-eslint
      # pkgs.vscode-marketplace.graphql.vscode-graphql
      # pkgs.vscode-marketplace.graphql.vscode-graphql-syntax
      # pkgs.vscode-marketplace.meganrogge.template-string-converter
      # pkgs.vscode-marketplace.sissel.shopify-liquid
      # pkgs.vscode-marketplace.styled-components.vscode-styled-components
      # pkgs.vscode-marketplace.stylelint.vscode-stylelint

      # content
      pkgs.vscode-marketplace.ctcuff.font-preview
      pkgs.vscode-marketplace.davidwang.ini-for-vscode
      pkgs.vscode-marketplace.codezombiech.gitignore
      pkgs.vscode-marketplace.editorconfig.editorconfig
      pkgs.vscode-marketplace.emilast.logfilehighlighter
      pkgs.vscode-marketplace.jock.svg
      pkgs.vscode-marketplace.ms-vscode.hexeditor
      pkgs.vscode-marketplace.redhat.vscode-yaml
      pkgs.vscode-marketplace.skellock.just
      pkgs.vscode-marketplace.tamasfe.even-better-toml
      pkgs.vscode-marketplace.tomoki1207.pdf

      # spelling
      pkgs.vscode-marketplace.streetsidesoftware.code-spell-checker
      pkgs.vscode-marketplace.streetsidesoftware.code-spell-checker-croatian
    ];
  };
}
