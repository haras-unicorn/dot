{ pkgs
, config
, system
, nix-vscode-extensions
, ...
}:

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
  programs.vscode.extensions = with nix-vscode-extensions.extensions."${system}"; [
    open-vsx-release.ms-dotnettools.csdevkit
    open-vsx-release.arcanis.vscode-zipfs
    open-vsx-release.bbenoist.nix
    open-vsx-release.bmalehorn.shell-syntax
    open-vsx-release.charliermarsh.ruff
    open-vsx-release.codezombiech.gitignore
    open-vsx-release.ctcuff.font-preview
    open-vsx-release.davidwang.ini-for-vscode
    open-vsx-release.dbaeumer.vscode-eslint
    open-vsx-release.editorconfig.editorconfig
    open-vsx-release.eeyore.yapf
    open-vsx-release.emilast.logfilehighlighter
    open-vsx-release.equinusocio.vsc-material-theme
    open-vsx-release.esbenp.prettier-vscode
    open-vsx-release.formulahendry.dotnet-test-explorer
    open-vsx-release.foxundermoon.shell-format
    open-vsx-release.gamunu.vscode-yarn
    open-vsx-release.github.copilot
    open-vsx-release.graphql.vscode-graphql
    open-vsx-release.graphql.vscode-graphql-syntax
    open-vsx-release.jock.svg
    open-vsx-release.meganrogge.template-string-converter
    open-vsx-release.ms-azuretools.vscode-docker
    open-vsx-release.ms-dotnettools.csharp
    open-vsx-release.ms-dotnettools.vscode-dotnet-runtime
    open-vsx-release.ms-playwright.playwright
    open-vsx-release.ms-pyright.pyright
    open-vsx-release.ms-python.debugpy
    open-vsx-release.ms-python.python
    open-vsx-release.ms-vscode-remote.remote-containers
    open-vsx-release.ms-vscode-remote.remote-ssh
    open-vsx-release.ms-vscode-remote.remote-ssh-edit
    open-vsx-release.ms-vscode.hexeditor
    open-vsx-release.ms-vscode.powershell
    open-vsx-release.ms-vscode.remote-explorer
    open-vsx-release.naumovs.color-highlight
    open-vsx-release.pkief.material-icon-theme
    open-vsx-release.redhat.vscode-yaml
    open-vsx-release.rust-lang.rust-analyzer
    open-vsx-release.selcukermaya.se-csproj-extensions
    open-vsx-release.shd101wyy.markdown-preview-enhanced
    open-vsx-release.sissel.shopify-liquid
    open-vsx-release.skellock.just
    open-vsx-release.styled-components.vscode-styled-components
    open-vsx-release.stylelint.vscode-stylelint
    open-vsx-release.tamasfe.even-better-toml
    open-vsx-release.thenuprojectcontributors.vscode-nushell-lang
    open-vsx-release.timonwong.shellcheck
    open-vsx-release.tomoki1207.pdf
    open-vsx-release.unifiedjs.vscode-mdx
    open-vsx-release.unifiedjs.vscode-remark
    open-vsx-release.usernamehw.errorlens
    open-vsx-release.vadimcn.vscode-lldb
    open-vsx-release.vscodevim.vim
    open-vsx-release.wayou.vscode-todo-highlight
  ];

  # NOTE: for OCD
  # ## Add/Remove VS Code extensions
  # 1. in `src/module/home/code/extensions.json` remove or add with just `name` and
  #    `publisher`
  # 2. run `just codext`
  # programs.vscode.extensions = builtins.filter
  #   (extension: extension != null)
  #   (builtins.map
  #     (extension:
  #       if builtins.hasAttr "platforms" extension.src && (! builtins.hasAttr "${system}" extension.src.platforms)
  #       then null
  #       else
  #         (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  #           vsix = builtins.fetchurl
  #             (if builtins.hasAttr "platforms" extension.src
  #             then ({ inherit (extension.src) name; } // extension.src.platforms.${system})
  #             else extension.src);
  #           mktplcRef = { inherit (extension) name publisher version; };
  #         }))
  #     (builtins.fromJSON (builtins.readFile ./extensions.json)));
}
