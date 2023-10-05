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
    # arcanis.vscode-zipfs -> NEED
    bbenoist.nix
    # bmalehorn.shell-syntax
    # ChakrounAnas.turbo-console-log
    codezombiech.gitignore
    charliermarsh.ruff
    # csharpier.csharpier-vscode -> NEED or omnisharp?
    # ctcuff.font-preview
    # DavidWang.ini-for-vscode
    dbaeumer.vscode-eslint
    editorconfig.editorconfig
    # eeyore.yapf -> NEED for python
    # emilast.LogFileHighlighter
    # Equinusocio.vsc-community-material-theme -> zhuangtongfa.material-theme
    esbenp.prettier-vscode
    # formulahendry.dotnet-test-explorer -> i would like to have this a LOT
    foxundermoon.shell-format
    # gamunu.vscode-yarn -> check if need
    github.copilot
    graphql.vscode-graphql
    graphql.vscode-graphql-syntax
    jock.svg
    # letrieu.expand-region
    # logerfo.sln-support
    # meganrogge.template-string-converter -> i would like to have this a LOT
    mikestead.dotenv
    ms-azuretools.vscode-docker
    ms-dotnettools.csharp
    # ms-dotnettools.vscode-dotnet-runtime -> check if need?
    # ms-playwright.playwright -> i would like to have this a LOT
    ms-pyright.pyright
    ms-python.python
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    # ms-vscode-remote.remote-ssh-edit
    ms-vscode.powershell
    # ms-vscode.remote-explorer
    naumovs.color-highlight
    pkief.material-icon-theme
    redhat.vscode-yaml
    rust-lang.rust-analyzer
    # selcukermaya.se-csproj-extensions
    shd101wyy.markdown-preview-enhanced
    # silesky.toggle-boolean
    # sissel.shopify-liquid -> i would like this a LOT for orchard core
    styled-components.vscode-styled-components
    # stylelint.vscode-stylelint -> NEED
    tamasfe.even-better-toml
    thenuprojectcontributors.vscode-nushell-lang
    timonwong.shellcheck
    tomoki1207.pdf
    unifiedjs.vscode-mdx
    # unifiedjs.vscode-remark
    usernamehw.errorlens
    vadimcn.vscode-lldb
    vscodevim.vim
    # wayou.vscode-todo-highlight
  ];
}
