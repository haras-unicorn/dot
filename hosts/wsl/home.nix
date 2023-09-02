{ pkgs, ... }:

let
  username = "nixos";
in
{
  programs.home-manager.enable = true;
  xdg.configFile."nixpkgs/config.nix".source = ../../assets/.config/nixpkgs/config.nix;

  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.sessionVariables = {
    VISUAL = "hx";
    EDITOR = "hx";
    PAGER = "bat";
  };
  home.shellAliases = {
    lg = "lazygit";
    cat = "bat";
    grep = "rg";
    rm = "rm -i";
    mv = "mv -i";
    la = "exa";

    pls = "sudo";
    bruh = "git";
    sis = "hx";
    yas = "yes";
  };
  home.packages = with pkgs; [
    # dev
    meld
    nil
    nixpkgs-fmt
    direnv
    nix-direnv
    python311
    python311Packages.python-lsp-server
    python311Packages.black
    dotnet-sdk_7
    omnisharp-roslyn
    nodejs_20
    nodePackages.bash-language-server
    nodePackages.yaml-language-server
    nodePackages.dockerfile-language-server-nodejs
    rustc
    cargo
    marksman

    # tui
    pciutils
    lsof
    dmidecode
    inxi
    hwinfo
    ncdu
    xclip
    woeusb
    lazydocker
    spotify-tui
    fd
    file
    duf
    unzip
    unrar
    sd
  ];

  # dev
  programs.git.enable = true;
  programs.git.delta.enable = true;
  programs.git.attributes = [
    "* text=auto eof=lf"
  ];
  programs.git.lfs.enable = true;
  programs.git.signing.key = "8A2BB645A7A84277A9D6BC41987A64C9A6B34535";
  programs.git.signing.signByDefault = true;
  programs.git.userEmail = "social@hrvojej.anonaddy.me";
  programs.git.userName = "Hrle";
  programs.git.extraConfig = {
    interactive.singleKey = true;
    init.defaultBranch = "main";
    pull.rebase = true;
    push.default = "upstream";
    push.followTags = true;
    rerere.enabled = true;
    merge.tool = "meld";
    "mergetool \"meld\"".cmd = ''meld "$LOCAL" "$MERGED" "$REMOTE" --output "$MERGED"'';
    color.ui = "auto";
  };
  programs.helix.enable = true;
  programs.helix.languages = {
    language = [
      {
        name = "python";
        auto-format = true;
        formatter = { command = "black"; };
      }
      {
        name = "nix";
        auto-format = true;
        formatter = { command = "nixpkgs-fmt"; };
      }
    ];
  };
  programs.helix.settings = {
    theme = "transparent";
    editor = {
      true-color = true;
      scrolloff = 999;
      auto-save = true;
      rulers = [ ];
      gutters = [ "diagnostics" "spacer" "diff" ];
    };
  };
  programs.helix.themes.transparent = {
    inherits = "everforest_dark";

    "ui.background" = { };
    "ui.statusline" = { fg = "fg"; };
  };

  # tui
  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;
  programs.nushell.enable = true;
  programs.nushell.extraEnv = ''
    $env.PATH = $"/home/${username}/bin:($env.PATH)"
    $env.PATH = $"bin:($env.PATH)"
  '';
  programs.nushell.extraConfig = ''
    $env.config = {
      show_banner: false

      edit_mode: vi
      cursor_shape: {
        vi_insert: line
        vi_normal: underscore
      }

      hooks: {
        pre_prompt: [{ ||
          let direnv = (direnv export json | from json)
          let direnv = if ($direnv | length) == 1 { $direnv } else { {} }
          $direnv | load-env
        }]
      }
    }
  '';
  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'λ '";
    PROMPT_INDICATOR_VI_NORMAL = "' '";
  };
  home.file."bin/recreate".text = ''
    #!/usr/bin/env bash
    set -eo pipefail

    command=switch
    comment="$1"
    if [[ "$1" == "boot" ]]; then
      command=boot
      comment="$2"
    fi
    if [[ -z "$comment" ]]; then
      comment="WIP"
    fi

    if [[ ! -d ~/repos/dotfiles ]]; then
     mkdir -p ~/repos
     git clone ssh://git@gitlab.com/hrle/dotfiles-nixos ~/src/dotfiles
    fi

    wd="$(pwd)"
    cd ~/repos/dotfiles
    git add .
    git commit -m "$comment"
    git push
    sudo nixos-rebuild "$command" --flake ~/repos/dotfiles#wsl
    cd "$wd"
  '';
  home.file."bin/recreate".executable = true;
  home.file."bin/update".text = ''
    #!/usr/bin/env bash
    set -eo pipefail

    command=switch
    comment="$1"
    if [[ "$1" == "boot" ]]; then
      command=boot
      comment="$2"
    fi
    if [[ -z "$comment" ]]; then
      comment="WIP"
    fi

    if [[ ! -d ~/repos/dotfiles ]]; then
     mkdir -p ~/repos
     git clone ssh://git@gitlab.com/hrle/dotfiles-nixos ~/src/dotfiles
    fi

    wd="$(pwd)"
    cd ~/repos/dotfiles
    nix flake update
    git add .
    git commit -m "$comment"
    git push
    sudo nixos-rebuild "$command" --flake ~/repos/dotfiles#wsl
    cd "$wd"
  '';
  home.file."bin/update".executable = true;
  home.file."bin/clean".text = ''
    #!/usr/bin/env bash
    set -eo pipefail

    nix-env --delete-generations 7d
    nix-store --gc
  '';
  home.file."bin/clean".executable = true;
  programs.starship.enable = true;
  programs.starship.enableNushellIntegration = true;
  xdg.configFile."starship.toml".source = ../../assets/.config/starship/starship.toml;
  programs.zoxide.enable = true;
  programs.zoxide.enableNushellIntegration = true;
  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    notARepository = "quit";
    promptToReturnFromSubprocess = false;
    gui = {
      showIcons = true;
    };
  };
  programs.htop.enable = true;
  programs.lf.enable = true;
  programs.bat.enable = true;
  programs.bat.config = {
    style = "header,rule,snip,changes";
  };
  programs.ripgrep.enable = true;
  programs.ripgrep.arguments = [
    "--max-columns=100"
    "--max-columns-preview"
    "--colors=auto"
    "--smart-case"
  ];
  programs.exa.enable = true;
  programs.exa.extraOptions = [
    "--all"
    "--list"
    "--color=always"
    "--group-directories-first"
    "--icons"
    "--group"
    "--header"
  ];

  # services
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "tty";
  programs.ssh.enable = true;

  home.stateVersion = "23.11";
}
