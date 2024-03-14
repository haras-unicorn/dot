{ pkgs, config, ... }:

# FIXME: add needed extensions to nixpkgs
# FIXME: vscodium doesn't work (on wayland)?

{
  shell.aliases = {
    code = "${pkgs."${config.dot.visual.pkg}"}/bin/${config.dot.visual.bin}";
  };

  programs.vscode.enable = true;
  programs.vscode.package = pkgs."${config.dot.visual.pkg}";
  programs.vscode.keybindings = (builtins.fromJSON (builtins.readFile ./keybindings.json));
  # NOTE: vscode uses ligher font weight
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

  # programs.vscode.enableExtensionUpdateCheck = false;
  # programs.vscode.enableUpdateCheck = false;
  # programs.vscode.mutableExtensionsDir = false;
  # programs.vscode.extensions = with pkgs.vscode-extensions; [
  #   # arcanis.vscode-zipfs -> NEED - maybe not if i use bun?
  #   bbenoist.nix
  #   # bmalehorn.shell-syntax
  #   codezombiech.gitignore
  #   # charliermarsh.ruff
  #   # ctcuff.font-preview
  #   # DavidWang.ini-for-vscode
  #   dbaeumer.vscode-eslint
  #   editorconfig.editorconfig
  #   # eeyore.yapf -> NEED for python
  #   # emilast.LogFileHighlighter
  #   equinusocio.vsc-material-theme
  #   esbenp.prettier-vscode
  #   # formulahendry.dotnet-test-explorer -> i would like to have this a LOT
  #   foxundermoon.shell-format
  #   # gamunu.vscode-yarn -> check if need
  #   github.copilot
  #   graphql.vscode-graphql
  #   graphql.vscode-graphql-syntax
  #   jock.svg
  #   # meganrogge.template-string-converter -> i would like to have this a LOT
  #   ms-azuretools.vscode-docker
  #   ms-dotnettools.csharp
  #   # ms-dotnettools.vscode-dotnet-runtime -> check if need?
  #   # ms-playwright.playwright -> i would like to have this a LOT
  #   ms-pyright.pyright
  #   ms-python.python
  #   # ms-vscode-remote.remote-containers
  #   ms-vscode-remote.remote-ssh
  #   # ms-vscode-remote.remote-ssh-edit
  #   ms-vscode.powershell
  #   # ms-vscode.remote-explorer
  #   naumovs.color-highlight
  #   pkief.material-icon-theme
  #   redhat.vscode-yaml
  #   rust-lang.rust-analyzer
  #   # selcukermaya.se-csproj-extensions
  #   shd101wyy.markdown-preview-enhanced
  #   # sissel.shopify-liquid -> i would like this a LOT for orchard core
  #   styled-components.vscode-styled-components
  #   # stylelint.vscode-stylelint -> NEED
  #   tamasfe.even-better-toml
  #   thenuprojectcontributors.vscode-nushell-lang
  #   timonwong.shellcheck
  #   tomoki1207.pdf
  #   unifiedjs.vscode-mdx
  #   # unifiedjs.vscode-remark
  #   usernamehw.errorlens
  #   vadimcn.vscode-lldb
  #   vscodevim.vim
  #   # wayou.vscode-todo-highlight
  #   skellock.just
  #   ms-vscode.hexeditor
  # ];
}
