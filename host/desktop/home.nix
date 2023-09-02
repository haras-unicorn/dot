{ pkgs, ... }:

{
  home.sessionVariables = {
    # TODO: not working cuz nushell?
    QT_QPA_PLATFORMTHEME = "gtk2";
    VISUAL = "hx";
    EDITOR = "hx";
    PAGER = "bat";
    BROWSER = "brave";
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

    # services
    keepmenu
    brightnessctl
    ntfs3g

    # apps
    ferdium
    keepassxc
    brave
    emote
    libreoffice-fresh
    obs-studio
    shotwell
    pinta
  ];

  # tui
  home.file."scripts/text-generation-webui".text = ''
    #!/usr/bin/env bash
    set -eo pipefail

    if [[ ! -d ~/repos/text-generation-webui ]]; then
      mkdir -p ~/repos
      git clone https://github.com/oobabooga/text-generation-webui ~/repos/text-generation-webui
    fi
    if [[ ! -d ~/repos/automatic1111-webui-nix ]]; then
      mkdir -p ~/repos
      git clone https://github.com/virchau13/automatic1111-webui-nix ~/repos/automatic1111-webui-nix
    fi
    cp ~/repos/automatic1111-webui-nix/*.nix ~/repos/text-generation-webui

    wd="$(pwd)"
    cd ~/repos/text-generation-webui

    nix develop --profile ./profile --command bash -c 'echo "Recorded profile"'
    cat <<END > ./webui.sh
      #!/usr/bin/env bash
      set -eo pipefail

      printf "Hello world!"
    END
    chmod +x ./webui.sh

    git add .
    git update-index --chmod=+x ./webui.sh
    git commit -m "Flake" && echo "Flake commited" || echo "Flake already commited"
    git pull

    echo "Running ./webui.sh"
    nix develop ./profile --command bash ./webui.sh

    cd "$wd"
  '';
  home.file."scripts/text-generation-webui".executable = true;
  home.file."scripts/recreate".text = ''
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
     git clone ssh://gitlab.com/hrle/dotfiles-nixos ~/repos/dotfiles
    fi

    wd="$(pwd)"
    cd ~/repos/dotfiles
    git add .
    git commit -m "$comment"
    git push
    sudo nixos-rebuild "$command" --flake ~/repos/dotfiles#desktop
    cd "$wd"
  '';
  home.file."scripts/recreate".executable = true;
  home.file."scripts/update".text = ''
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
     git clone ssh://gitlab.com/hrle/dotfiles-nixos ~/repos/dotfiles
    fi

    wd="$(pwd)"
    cd ~/repos/dotfiles
    nix flake update
    git add .
    git commit -m "$comment"
    git push
    sudo nixos-rebuild "$command" --flake ~/repos/dotfiles#desktop
    cd "$wd"
  '';
  home.file."scripts/update".executable = true;
  home.file."scripts/clean".text = ''
    #!/usr/bin/env bash
    set -eo pipefail

    nix-env --delete-generations 7d
    nix-store --gc
  '';
  home.file."scripts/clean".executable = true;
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
  programs.nnn.enable = true;
  programs.nnn.package = pkgs.nnn.override { withNerdIcons = true; };
  programs.nnn.bookmarks = {
    r = "~/repos";
    d = "~/repos/dotfiles";
  };
  programs.nnn.extraPackages = with pkgs; [
    mpv
    nsxiv
    zathura
    tabbed
    file
    xdotool
    atool
    libarchive
    unrar
    p7zip
    vim-full
  ];
  programs.nnn.plugins = {
    mappings = {
      p = "preview-tabbed";
      o = "nuke";
      f = "fzopen";
    };
  };
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
  programs.feh.enable = true;

  # services
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "gnome3";
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "/home/${username}/.ssh/personal";
    };
    "gitlab.com" = {
      user = "git";
      identityFile = "/home/${username}/.ssh/personal";
    };
  };
  services.syncthing.enable = true;
  services.udiskie.enable = true;
  services.flameshot.enable = true;
  services.redshift.enable = true;
  services.redshift.provider = "geoclue2";
  services.network-manager-applet.enable = true;
  services.dunst.enable = true;
  # home.file.".config/dunst".source = ../../assets/.config/dunst;
  programs.rofi.enable = true;
  # home.file.".config/rofi".source = ../../assets/.config/rofi;
  xdg.configFile."keepmenu/config.ini".source = ../../assets/.config/keepmenu/config.ini;
  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  services.betterlockscreen.enable = true;
  home.file.".local/share/wallpapers".source = ../../assets/.local/share/wallpapers;
  services.spotifyd.enable = true;
  services.spotifyd.package = pkgs.spotifyd.override { withKeyring = true; };
  # security add-generic-password -s spotifyd -D rust-keyring -a <your username> -w
  services.spotifyd.settings = {
    global = {
      username = "ftsedf157kfova8yuzoq1dfax";
      use_keyring = true;
      use_mpris = true;
      dbus_type = "session";
      backend = "pulseaudio";
      bitrate = 320;
      cache_path = "/home/${username}/.cache/spotifyd";
      volume_normalisation = true;
      device_type = "computer";
      device_name = "${username}";
      zeroconf_port = 8888;
    };
  };
  services.playerctld.enable = true;
  xdg.configFile."qtile".source = ../../assets/.config/qtile;

  # theming
  fonts.fontconfig.enable = true;
  gtk.enable = true;
  gtk.font.package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
  gtk.font.name = "JetBrainsMono Nerd Font";
  gtk.iconTheme.name = "BeautyLine";
  gtk.iconTheme.package = pkgs.beauty-line-icon-theme;
  gtk.theme.name = "Sweet-Dark";
  gtk.theme.package = pkgs.sweet;
  qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "Sweet-Dark";
  qt.style.package = pkgs.sweet;
}
