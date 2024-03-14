{ pkgs, config, ... }:

# FIXME: vscodium doesn't work (on wayland)?

# TODO: add needed extensions to nixpkgs

{
  shell.aliases = {
    code = "${pkgs."${config.dot.visual.pkg}"}/bin/${config.dot.visual.bin}";
  };

  programs.vscode.enable = true;
  programs.vscode.package = pkgs."${config.dot.visual.pkg}";
  programs.vscode.keybindings = (builtins.fromJSON (builtins.readFile ./keybindings.json));
  programs.vscode.userSettings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    "editor.fontFamily" = ''"${config.dot.font.nerd.name}"'';
    "debug.console.fontFamily" = ''"${config.dot.font.nerd.name}"'';
    "terminal.integrated.fontFamily" = ''"${config.dot.font.nerd.name}"'';
    "editor.fontSize" = "${builtins.toString (config.dot.font.size.medium + 1)}";
    "debug.console.fontSize" = "${builtins.toString (config.dot.font.size.small + 1)}";
    "terminal.integrated.fontSize" = "${builtins.toString (config.dot.font.size.small + 1)}";
    "terminal.external.linuxExec" = "${pkgs."${config.dot.term.pkg}"}/bin/${config.dot.term.bin}";
    "terminal.integrated.profiles.linux" = {
      "${config.dot.shell.module}" = {
        "path" = "${pkgs."${config.dot.shell.pkg}"}/bin/${config.dot.shell.bin}";
      };
      "bash" = {
        "path" = "${pkgs.bashInteractiveFHS}/bin/bash";
        "icon" = "terminal-bash";
      };
    };
    "terminal.integrated.defaultProfile.linux" = "${config.dot.shell.module}";
    "terminal.integrated.automationProfile.linux" = {
      "path" = "${pkgs.bashInteractiveFHS}/bin/bash";
    };
  };

  programs.vscode.enableExtensionUpdateCheck = false;
  programs.vscode.enableUpdateCheck = false;
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.extensions =
    with pkgs.vscode-extensions;
    with pkgs.vscode-utils;
    with pkgs.lib; [
      bbenoist.nix
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-zipfs";
          publisher = "arcanis";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "shell-syntax";
          publisher = "bmalehorn";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      codezombiech.gitignore
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "ruff";
          publisher = "charliermarsh";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "font-preview";
          publisher = "ctcuff";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "ini-for-vscode";
          publisher = "DavidWang";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      dbaeumer.vscode-eslint
      editorconfig.editorconfig
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "yapf";
          publisher = "eeyore";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "LogFileHighlighter";
          publisher = "emilast";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      equinusocio.vsc-material-theme
      esbenp.prettier-vscode
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "dotnet-test-explorer";
          publisher = "formulahendry";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      foxundermoon.shell-format
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-yarn";
          publisher = "gamunu";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      github.copilot
      graphql.vscode-graphql
      graphql.vscode-graphql-syntax
      jock.svg
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "template-string-converter";
          publisher = "meganrogge";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      ms-azuretools.vscode-docker
      ms-dotnettools.csharp
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-dotnet-runtime";
          publisher = "ms-dotnettools";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "playwright";
          publisher = "ms-playwright";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      ms-pyright.pyright
      ms-python.python
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "remote-containers";
          publisher = "ms-vscode-remote";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "remote-explorer";
          publisher = "ms-vscode";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      pkief.material-icon-theme
      redhat.vscode-yaml
      rust-lang.rust-analyzer
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "se-csproj-extensions";
          publisher = "selcukermaya";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "shopify-liquid";
          publisher = "sissel";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      styled-components.vscode-styled-components
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-stylelint";
          publisher = "stylelint";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      tamasfe.even-better-toml
      thenuprojectcontributors.vscode-nushell-lang
      timonwong.shellcheck
      tomoki1207.pdf
      unifiedjs.vscode-mdx
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-remark";
          publisher = "unifiedjs";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      vadimcn.vscode-lldb
      vscodevim.vim
      (buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-todo-highlight";
          publisher = "wayou";
          version = "";
          sha256 = "";
        };
        meta = { license = licenses.mit; };
      })
      ms-vscode.hexeditor
    ];
}
