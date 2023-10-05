{ pkgs, ... }:

{
  programs.vscode.enable = true;
  # programs.vscode.package = (pkgs.symlinkJoin {
  #   name = "code";
  #   paths = [ pkgs.vscode ];
  #   buildInputs = [ pkgs.makeWrapper ];
  #   postBuild = ''
  #     wrapProgram $out/bin/code --append-flags --ozone-platform-hint=auto
  #   '';
  # });
  programs.vscode.enableExtensionUpdateCheck = false;
  programs.vscode.enableUpdateCheck = false;
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.keybindings = (builtins.fromJSON (builtins.readFile ./keybindings.json));
  programs.vscode.userSettings = (builtins.fromJSON (builtins.readFile ./settings.json));
  programs.vscode.extensions = with pkgs.vscode-extensions; [
    arcanis.vscode-zipfs
    bbenoist.Nix
    bmalehorn.shell-syntax
    ChakrounAnas.turbo-console-log
    codezombiech.gitignore
    charliermarsh.ruff
    csharpier.csharpier-vscode
    ctcuff.font-preview
    DavidWang.ini-for-vscode
    dbaeumer.vscode-eslint
    EditorConfig.EditorConfig
    eeyore.yapf
    emilast.LogFileHighlighter
    Equinusocio.vsc-community-material-theme
    esbenp.prettier-vscode
    formulahendry.dotnet-test-explorer
    foxundermoon.shell-format
    gamunu.vscode-yarn
    GitHub.copilot
    GraphQL.vscode-graphql
    GraphQL.vscode-graphql-syntax
    jock.svg
    letrieu.expand-region
    logerfo.sln-support
    meganrogge.template-string-converter
    mikestead.dotenv
    ms-azuretools.vscode-docker
    ms-dotnettools.csharp
    ms-dotnettools.vscode-dotnet-runtime
    ms-ossdata.vscode-postgresql
    ms-playwright.playwright
    ms-pyright.pyright
    ms-python.python
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode-remote.remote-wsl
    ms-vscode.powershell
    ms-vscode.remote-explorer
    naumovs.color-highlight
    PKief.material-icon-theme
    redhat.vscode-yaml
    rust-lang.rust-analyzer
    selcukermaya.se-csproj-extensions
    shd101wyy.markdown-preview-enhanced
    silesky.toggle-boolean
    sissel.shopify-liquid
    styled-components.vscode-styled-components
    stylelint.vscode-stylelint
    tamasfe.even-better-toml
    TheNuProjectContributors.vscode-nushell-lang
    timonwong.shellcheck
    tomoki1207.pdf
    unifiedjs.vscode-mdx
    unifiedjs.vscode-remark
    usernamehw.errorlens
    vadimcn.vscode-lldb
    vscodevim.vim
    wayou.vscode-todo-highlight
  ];
}
