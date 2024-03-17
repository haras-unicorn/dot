{ pkgs
, config
, ...
}:

# FIXME: vscodium doesn't work (on wayland)?
# FIXME: the new csharp extensions just dont work (https://github.com/microsoft/vscode-dotnettools/issues/225)
# TODO: helix emulation when it gets better

{
  config = pkgs.lib.mkIf (config.dot.visual.module == "code") {
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
      "editor.fontSize" = config.dot.font.size.medium + 1;
      "debug.console.fontSize" = config.dot.font.size.small + 1;
      "terminal.integrated.fontSize" = config.dot.font.size.small + 1;
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
    programs.vscode.extensions = with pkgs.vscode-marketplace; [
      # misc
      github.copilot
      ms-playwright.playwright
      ms-azuretools.vscode-docker
      # jasew.vscode-helix-emulation
      vscodevim.vim

      # ui
      usernamehw.errorlens
      wayou.vscode-todo-highlight
      naumovs.color-highlight

      # theme
      akamud.vscode-theme-onedark
      pkief.material-icon-theme

      # remote
      ms-vscode-remote.remote-containers
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode.remote-explorer

      # rust
      vadimcn.vscode-lldb
      rust-lang.rust-analyzer

      # csharp
      # ms-dotnettools.csharp
      # ms-dotnettools.csdevkit
      # ms-dotnettools.vscode-dotnet-runtime
      pkgs.vscode-extensions.ms-dotnettools.csharp
      formulahendry.dotnet-test-explorer
      selcukermaya.se-csproj-extensions

      # web
      gamunu.vscode-yarn
      arcanis.vscode-zipfs
      dbaeumer.vscode-eslint
      graphql.vscode-graphql
      graphql.vscode-graphql-syntax
      meganrogge.template-string-converter
      sissel.shopify-liquid
      styled-components.vscode-styled-components
      stylelint.vscode-stylelint
      esbenp.prettier-vscode

      # python
      charliermarsh.ruff
      eeyore.yapf
      ms-pyright.pyright
      ms-python.debugpy
      ms-python.python

      # nix
      bbenoist.nix

      # shell
      bmalehorn.shell-syntax
      foxundermoon.shell-format
      ms-vscode.powershell
      thenuprojectcontributors.vscode-nushell-lang
      timonwong.shellcheck

      # markdown
      shd101wyy.markdown-preview-enhanced
      unifiedjs.vscode-mdx
      unifiedjs.vscode-remark

      # data
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
    ];
  };
}
