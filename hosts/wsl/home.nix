{ pkgs, ... }:

let
  username = "nixos";
in
{
  programs.home-manager.enable = true;
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;
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
  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;
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
    PROMPT_INDICATOR_VI_INSERT = "'i '";
    PROMPT_INDICATOR_VI_NORMAL = "'n '";
  };
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
    sudo nixos-rebuild "$command" --flake ~/repos/dotfiles#wsl
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
    sudo nixos-rebuild "$command" --flake ~/repos/dotfiles#wsl
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

  # services
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "tty";
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

  home.stateVersion = "23.11";
}
