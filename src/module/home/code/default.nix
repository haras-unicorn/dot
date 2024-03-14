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
    ms-dotnettools.csdevkit
    arcanis.vscode-zipfs
    bbenoist.nix
    bmalehorn.shell-syntax
    charliermarsh.ruff
    codezombiech.gitignore
    ctcuff.font-preview
    davidwang.ini-for-vscode
    dbaeumer.vscode-eslint
    editorconfig.editorconfig
    eeyore.yapf
    emilast.logfilehighlighter
    equinusocio.vsc-material-theme
    esbenp.prettier-vscode
    formulahendry.dotnet-test-explorer
    foxundermoon.shell-format
    gamunu.vscode-yarn
    github.copilot
    graphql.vscode-graphql
    graphql.vscode-graphql-syntax
    jock.svg
    meganrogge.template-string-converter
    ms-azuretools.vscode-docker
    ms-dotnettools.csharp
    ms-dotnettools.vscode-dotnet-runtime
    ms-playwright.playwright
    ms-pyright.pyright
    ms-python.debugpy
    ms-python.python
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode.hexeditor
    ms-vscode.powershell
    ms-vscode.remote-explorer
    naumovs.color-highlight
    pkief.material-icon-theme
    redhat.vscode-yaml
    rust-lang.rust-analyzer
    selcukermaya.se-csproj-extensions
    shd101wyy.markdown-preview-enhanced
    sissel.shopify-liquid
    skellock.just
    styled-components.vscode-styled-components
    stylelint.vscode-stylelint
    tamasfe.even-better-toml
    thenuprojectcontributors.vscode-nushell-lang
    timonwong.shellcheck
    tomoki1207.pdf
    unifiedjs.vscode-mdx
    unifiedjs.vscode-remark
    usernamehw.errorlens
    vadimcn.vscode-lldb
    vscodevim.vim
    wayou.vscode-todo-highlight
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
