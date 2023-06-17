{ pkgs, ... }:

let
  username = "virtuoso";
in
{
  programs.home-manager.enable = true;

  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.sessionVariables = {
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
    python311Packages.python-lsp-server
    nil
    nixpkgs-fmt

    # tui
    ncdu
    xclip
    spotify-tui
    feh
    lazydocker
    file
    unzip
    unrar
    ripgrep
    lsof

    # services
    keepmenu
    brightnessctl
    gnome.seahorse

    # apps
    ferdium
    keepassxc
    brave
  ];

  # dev
  programs.git.enable = true;
  programs.git.delta.enable = true;
  programs.git.attributes = [
    "* text=auto eof=lf"
  ];
  programs.git.lfs.enable = true;
  # programs.git.signing.key = "8A2BB645A7A84277A9D6BC41987A64C9A6B34535";
  # programs.git.signing.signByDefault = true;
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
  programs.gpg.enable = true;
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
    # theme = "palenight";
    editor = {
      file-picker = {
        hidden = false;
      };
    };
  };
  programs.helix.themes = {
    palenight =
      let
        # transparent = "#000000";
        background = "#191349";
        foreground = "#c7d5ff";
        black = "#132339";
        white = "#ffddff";
        blue = "#82aaff";
        cyan = "#89ddff";
        green = "#c3e88d";
        magenta = "#c792ea";
        # red = "#ff5874";
        yellow = "#ffeb95";
        brightBlack = "#3c435e";
        brightWhite = "#ffffff";
        brightBlue = "#92baff";
        brightCyan = "#99fdff";
        brightGreen = "#c3f88d";
        brightMagenta = "#d792fa";
        brightRed = "#ff6884";
        brightYellow = "#fffba5";
        dimBlack = "#000200";
        dimWhite = "#ddccdd";
        dimBlue = "#72baff";
        # dimCyan = "#79edff";
        # dimGreen = "#b3d87d";
        # dimMagenta = "#b782da";
        # dimRed = "#ff4884";
        # dimYellow = "#ffdb85";
      in
      {
        "ui.background" = background;
        "ui.background.separator" = dimWhite;
        "ui.cursor" = white;
        "ui.cursor.normal" = white;
        "ui.cursor.insert" = white;
        "ui.cursor.select" = white;
        "ui.cursor.match" = green;
        "ui.cursor.primary" = white;
        "ui.cursor.primary.normal" = white;
        "ui.cursor.primary.insert" = white;
        "ui.cursor.primary.select" = white;
        "ui.debug.breakpoint" = brightRed;
        "ui.debug.active" = brightBlue;
        "ui.gutter" = dimBlack;
        "ui.gutter.selected" = white;
        "ui.highlight.frameline" = yellow;
        "ui.linenr" = white;
        "ui.linenr.selected" = brightWhite;
        "ui.statusline" = foreground;
        "ui.statusline.inactive" = dimWhite;
        "ui.statusline.normal" = green;
        "ui.statusline.insert" = blue;
        "ui.statusline.select" = magenta;
        "ui.statusline.separator" = dimWhite;
        "ui.popup" = background;
        "ui.popup.info" = cyan;
        "ui.window" = black;
        "ui.help" = foreground;
        "ui.text" = foreground;
        "ui.text.focus" = white;
        "ui.text.inactive" = dimWhite;
        "ui.text.info" = brightCyan;
        "ui.virtual.ruler" = dimWhite;
        "ui.virtual.whitespace" = dimWhite;
        "ui.virtual.indent-guide" = dimWhite;
        "ui.virtual.inlay-hint" = dimWhite;
        "ui.virtual.inlay-hint.parameter" = brightCyan;
        "ui.virtual.inlay-hint.type" = brightMagenta;
        "ui.virtual.wrap" = dimWhite;
        "ui.menu" = brightBlack;
        "ui.menu.selected" = blue;
        "ui.menu.scroll" = { fg = brightBlue; bg = dimBlue; };
        "ui.selection" = brightBlue;
        "ui.selection.primary" = brightBlue;
        "ui.highlight" = brightYellow;
        "ui.cursorline.primary" = dimWhite;
        "ui.cursorline.secondary" = dimWhite;
        "ui.cursorcolumn.primary" = dimWhite;
        "ui.cursorcolumn.secondary" = dimWhite;
        "warning" = brightYellow;
        "error" = brightRed;
        "info" = brightCyan;
        "hint" = brightGreen;
        "diagnostic" = { modifiers = [ "underlined" ]; };
        "diagnostic.hint" = brightGreen;
        "diagnostic.info" = brightCyan;
        "diagnostic.warning" = brightYellow;
        "diagnostic.error" = brightRed;
      };
  };

  # tui
  programs.kitty.enable = true;
  programs.kitty.extraConfig = builtins.readFile ../../assets/.config/kitty/kitty.conf;
  programs.nushell.enable = true;
  programs.nushell.extraEnv = ''
    def-env ensure-path [new_path: string] {
      let updated_env_path = (
        if ($env.PATH | split row ":" | any { |it| $it == $new_path }) {
          $env.PATH
        }
        else {
          $"($new_path):($env.PATH)"
        }
      )
      let-env PATH = $updated_env_path
    }

    ensure-path "/home/${username}/scripts"
    ensure-path "/home/${username}/bin"
    ensure-path "scripts"
    ensure-path "bin"
  '';
  programs.nushell.extraConfig = ''
    let-env config = {
      show_banner: false
      edit_mode: vi
      cursor_shape: {
        vi_insert: line
        vi_normal: underscore
      }
    }
  '';
  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'i '";
    PROMPT_INDICATOR_VI_NORMAL = "'n '";
  };
  home.file."scripts/stable-diffusion-webui".text = ''
    #!/usr/bin/env bash
    set -eo pipefail

    if [[ ! -d ~/repos/stable-diffusion-webui ]]; then
      mkdir -p ~/repos
      git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ~/repos/stable-diffusion-webui
    fi
    if [[ ! -d ~/repos/automatic1111-webui-nix ]]; then
      mkdir -p ~/repos
      git clone https://github.com/virchau13/automatic1111-webui-nix ~/repos/automatic1111-webui-nix
    fi
    wd="$(pwd)"
    cp ~/repos/automatic1111-webui-nix/*.nix ~/repos/stable-diffusion-webui
    cd ~/repos/stable-diffusion-webui
    if [[ ! -x ./webui.sh ]]; then
      printf "Stable Diffusion WebUI script not present\n.Exiting...\n"
      exit 1
    fi
    nix develop --command bash -c " \
      export COMMANDLINE_ARGS="--listen --enable-insecure-extensions-access --xformers --opt-sdp-no-mem-attention --no-half-vae --update-all-extensions --skip-torch-cuda-test" && \
      export TORCH_COMMAND="pip install torch==2.0.1+cu117 --extra-index-url https://download.pytorch.org/whl/cu117" && \
      export NO_TCMALLOC="True" && \
      source ./venv/bin/activate && \
      exec python launch.py \
    "
    cd "$wd"
  '';
  home.file."scripts/stable-diffusion-webui".executable = true;
  programs.starship.enable = true;
  programs.starship.enableNushellIntegration = true;
  home.file.".config/starship.toml".source = ../../assets/.config/starship/starship.toml;
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

  # services
  services.gnome-keyring.enable = true;
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "/home/${username}/.ssh/keys/personal";
    };
    "gitlab.com" = {
      user = "git";
      identityFile = "/home/${username}/.ssh/keys/personal";
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
  home.file.".config/keepmenu/config.ini".source = ../../assets/.config/keepmenu/config.ini;
  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  services.betterlockscreen.enable = true;
  home.file.".local/share/wallpapers".source = ../../assets/.local/share/wallpapers;
  services.spotifyd.enable = true;
  services.spotifyd.package = pkgs.spotifyd.override { withKeyring = true; };
  services.spotifyd.settings = {
    global = {
      username = "ftsedf157kfova8yuzoq1dfax";
      use_keyring = true;
      use_mpris = true;
      backend = "pulseaudio";
      device_name = "${username}";
      bitrate = 320;
      cache_path = "/home/${username}/.cache/spotifyd";
      volume_normalisation = true;
      device_type = "computer";
    };
  };
  services.playerctld.enable = true;
  home.file.".config/qtile".source = ../../assets/.config/qtile;

  # theming
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

  home.stateVersion = "23.11";
}
