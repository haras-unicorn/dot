{
  self.devShells.default = {
    flake = true;

    value =
      {
        config,
        lib,
        pkgs,
        self,
        ...
      }:
      let
        namespace = self.lib.overlays.namespace;

        prettierConfig = (pkgs.formats.yaml { }).generate "prettier.yaml" {
          printWidth = 80;
          tabWidth = 2;
          useTabs = false;
          trailingComma = "all";
          endOfLine = "lf";
          proseWrap = "always";
        };

        markdownlintConfig = (pkgs.formats.json { }).generate "markdownlint.json" {
          "$schema" =
            "https://raw.githubusercontent.com/DavidAnson/markdownlint/main/schema/markdownlint-config-schema.json";
          "no-duplicate-heading" = false;
        };

        markdownLinkCheckConfig = (pkgs.formats.json { }).generate "markdown-link-check.json" {
          ignorePatterns = [
            { pattern = "^#"; }
            { pattern = "^https://localhost"; }
            { pattern = "^http://localhost"; }
            { pattern = "^https://haras-unicorn.github.io/dot"; }
            { pattern = "^https://github.com/haras-unicorn/dot"; }
          ];
        };

        prettierIgnore = pkgs.writeText "prettierignore" ''
          .direnv
          .env
          *.lock
        '';

        cspellWords = lib.filter (word: word != "") (
          lib.splitString " " (
            lib.replaceStrings [ "\n" ] [ " " ] ''
              GCRA GETPIN Tunables aarch64 abiword activewindow agentic ahmia aieos
              alpinelinux alsa amdgpu ananicy anthropic anythingllm aplay appimage
              appname arcanis archlinux aspnetcorerazor asrouter astimezone asyncio
              attrset attrsets autohide avahi bbenoist behaviour betterlockscreen
              binde bindm binfmt bitburner bitwarden blueman bmalehorn bookworm
              breakpad brightnessctl bruh bubblewrap bwrap cachix cachyos captioner
              captivedetect cdrom certilia charliermarsh chdir chrony chronyd
              ckgqnyjqy claude clawhub clearsitedata cmdline codeberg codegen
              codezombiech comfyui compiz conntrack contentblocking controld conv
              convo coredns corelocation coreutils coreweave creds crlite crosspipe
              crossref csdevkit ctcuff ctstate cuda danth darkreader datareporting
              davidanson davidwang dbaeumer dbeaver dbus dconf ddccontrol ddcutil
              debugpy deepinfra deepseek direnv dmenu dnssec doas dont dotenv
              dotnettools downspeed dpms driversi drun duckduckgo dunst dunstrc
              earlyoom easyeffects eeprom eglinfo elif ellipsize emilast emptively
              environement envrc envsubst erikreider errorlens esac esbenp espeak
              expanduser extlinux ezdd facter fakespot fancontrol fastmod fbcat
              fbgrab fenix ferdium fetchgit fetchurl findutils firstparty flac
              flakehub flatseal foldfix foldl fontsize formfill foxundermoon fract
              freedns freesound freetube gabi gadiguibou gameid gamemode gamescope
              gammaray gammastep gamunu geoclue gerg gguf ghostty gitc gitea
              github-mcp-server gitui gles glsl glxinfo gnugrep gnused gpsd grayscale
              greetd gstreamer gsync gtklock gvfs hackernews hackr haras haraspkgs
              healthreport helvum hexeditor highligh highlightedyank highrr hlsearch
              homeserver htmlaboutaddons huggingface hwmon hyprctl hyprcursor
              hyprpicker hyprpolkitagent iconname identityfile ifname imap inputbar
              ints iseconds isoformat jasew jitless journalctl kando kawase kdbx
              keepassxc keepmenu keybind keybinds keyboar keyboardlayout keymap
              killactive langservers lazydocker lazyjournal lazysql lcpxfnx libav
              libdecor libexec libinput libnotify libqtile libraspberrypi librechat
              librewolf libuuid libva libvdpau libvirtd libx linecap linejoin
              listview llama-moe-cache llamacpp lldb lnav localip localipv localtimed
              lockscreen logfilehighlighter loglevel losslesscut lutris magick
              mainbox makoctl mangohud marijanp matroska meganrogge meilisearch
              menues mesg metacharacters mgnt middlemouse mijorus mimetypes mioi
              missioncenter mistralrs mktemp mlock mmap mmproj modelcontextprotocol
              modeset modesetting monadtall morgan movefocus movetoworkspace
              movewindow mozlz mstone msvideo msword mtok multimodal musnix mxpbmm
              nari naumovs nemo netlink netns networkmanager networkmanagerapplet
              newtabpage newwindow nftables niks niri nixboot nixfmt nixos nixpkgs
              nixroot nmaster nochatui noctalia noctalia-dev nodev noerror
              nofriendsui nomacs nonreparenting nonsponsored noto novita npmjs nruu
              nspawn nsswitch ntfs nufmt numlock numtide nushell nvenc nvidiactl
              nvtop ocsp officedocument oflag okular ollama omarchy omnisharp oneshot
              ongunm onnx openclaw opencode opendocument openfang openlibrary openpage
              openrouter opensearch opensearchdescription openwebui openxmlformats
              optimise optimus optoutstudies otxt passthru pbmode pcmanfm pdfjs
              peerconnection performatively pgxz picom pinentry pipefail pipewire
              piratebay pkgs pkief pkill playerctl playerctld pname polkit polybar
              postrouting powermenu poweroff powersave powertop presentationml
              privatebrowsing procname procps progressbar protonpath protontricks
              psutil pulseaudio purescript pushback pwtku pwvucontrol pyenv pylsp
              pypi qtgraphicaleffects qtile qtwayland quickactions quickemu quickget
              quicksuggest qwen radeon rasi raspberrypi rawvideo readlink
              recentsearches redmi reflog regdom regionrecord regionshot regreet
              relace rels remmina remotetab renice rerere resizeactive resizewindow
              resolv rlang roboto rocm rofi rtcip rtkit rustc rustscan rycee
              safetensors saivert sandboxed sandboxing sarah screenchange screenrecord
              screenrecords scrolloff searchform searx searxng selcukermaya septabee
              serviceworker sessionstorage setgid setuid shadertoy shellcheck shfmt
              shlvl shotcut shuf signon signons sigusr sissel skellock socat
              sourcehut speechd spicetify startpage statusline stdenv stdrename
              steamcompattool strikethrough stylix submap substituters suidsgid
              supermaven swaybg swayidle swayosd switchxkblayout swtpm syncthing
              syscalls systray taesd tamasfe taplo tasklist teamviewer terminfo
              tesseract textwidth thenuprojectcontributors timespec timesyncd
              timonwong tmpfiles tmpfs tmpin tmpout todowrite togglefloating togroup
              tokei tomoki toolbelt toolsai toolsets toplevel topsites totp treefmt
              tuigreet tulwn ubatch ublock uids uitour undrawn ungoogled unifiedjs
              unmute unsloth unstar unsubmitted upower upspeed urlbar usbutils
              usernamehw userprefs usql uuidgen uwsgi vaapi vadimcn vainfo valkey
              vcodec vdpau vdpauinfo venv vesktop veth vfat vicmd videodriver
              vimium virt virtio virtualenv virtualisation visio vlang vscodevim
              vsync vulkaninfo waybar wayou wayprompt webchannel webcompat webfetch
              webgl webgpu webp webrender webrtc websearch webui wezterm wgbibhngv
              widevinecdm windowrule windowrules windowrulev winearch winecfg
              wineprefix winetricks wiremix wireplumber wlogout wlrobs wmname woeusb
              wofi wordprocessingml worktree wpctl wrapup wtype wwmm x86_64
              xarchiver xclip xcompmgr xcursor xinerama xlink xmonad xsessions xtask
              xvxl xwayland xwaylandvideobridge xworkspaces yapf yazi ydotool zeditor
              zenity zeroclaw zeroclawlabs zipfs zlibrary zram editorconfig
              prettierignore cspell markdownlint markdown-link-check hx shfmt tidy
              nixos-rebuild MEMLOCK arstechnica autoupdater bleepingcomputer
              handback notif unsandboxed wakeup unreviewed
            ''
          )
        );

        cspellConfig = (pkgs.formats.yaml { }).generate "cspell.yaml" {
          useGitignore = true;
          version = "0.2";
          language = "en";
          ignorePaths = [
            "assets/**/*"
            "**/*.patch"
            "src/modules/services/searxng/engines.json"
            "src/deprecated/zeroclaw/morgan-fetch.json"
          ];
          ignoreWords = cspellWords;
        };

        toml = pkgs.formats.toml { };

        helixServers = lib.mapAttrs (
          _: server:
          {
            inherit (server) command;
          }
          // lib.optionalAttrs (server.arguments != [ ]) {
            args = server.arguments;
          }
          // lib.optionalAttrs (server.config != { }) {
            inherit (server) config;
          }
        ) config.languages.servers;

        helixLanguages = lib.mapAttrsToList (
          name: language:
          {
            inherit name;
            auto-format = language.auto-format;
          }
          // lib.optionalAttrs (language.servers != [ ]) {
            language-servers = language.servers;
          }
          // lib.optionalAttrs (language.formatter != null) {
            formatter = {
              inherit (language.formatter) command;
            }
            // lib.optionalAttrs (language.formatter.arguments != [ ]) {
              args = language.formatter.arguments;
            };
          }
        ) config.languages.languages;

        helixLanguagesToml = toml.generate "languages.toml" (
          lib.optionalAttrs (helixServers != { }) {
            language-server = helixServers;
          }
          // lib.optionalAttrs (helixLanguages != [ ]) {
            language = helixLanguages;
          }
        );

        nixfmtWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "nixfmt";
          package = pkgs.nixfmt;
        };

        prettierWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "prettier";
          package = pkgs.prettier;
          env.NODE_OPTIONS = "--jitless";
        };

        taploWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "taplo";
          package = pkgs.taplo;
        };

        cspellWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "cspell";
          package = pkgs.cspell;
        };

        shfmtWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "shfmt";
          package = pkgs.shfmt;
        };

        tidyWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "tidy";
          package = pkgs.html-tidy;
        };

        hxWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "hx";
          package = pkgs.helix;
          files = {
            "~/.cache/helix" = {
              mode = "rw";
            };
            ".helix/languages.toml" = {
              mode = "ro";
              source = helixLanguagesToml;
            };
          };
        };
      in
      {
        name = "dot";

        packages = with pkgs; [
          nil
          nixos-facter
          nixos-rebuild

          github-cli
          nushell
          helix
          opencode
          fd
          ripgrep
          fastmod
          lazygit

          bash-language-server
          yaml-language-server
          vscode-langservers-extracted
          markdownlint-cli
          markdown-link-check
          marksman

          nixfmtWrapped
          prettierWrapped
          taploWrapped
          cspellWrapped
          shfmtWrapped
          tidyWrapped
          hxWrapped
        ];

        bwrap.files = {
          "cspell.yaml".source = cspellConfig;
          ".prettierignore".source = prettierIgnore;
        };

        editorconfig = {
          enable = true;
          settings."*" = {
            end_of_line = "lf";
            charset = "utf-8";
            max_line_length = 80;
            indent_style = "space";
            indent_size = 2;
            tab_width = 2;
            insert_final_newline = true;
            trim_trailing_whitespace = true;
          };
        };

        languages = {
          servers = {
            nil.command = "nil";

            bash-language-server = {
              command = "bash-language-server";
              arguments = [ "start" ];
            };

            taplo = {
              command = "taplo";
              arguments = [
                "lsp"
                "stdio"
              ];
            };

            yaml-language-server = {
              command = "yaml-language-server";
              arguments = [ "--stdio" ];
            };

            marksman = {
              command = "marksman";
              arguments = [ "server" ];
            };

            nu-lsp = {
              command = "nu";
              arguments = [ "--lsp" ];
            };

            vscode-json-language-server = {
              command = "vscode-json-language-server";
              arguments = [ "--stdio" ];
              config = {
                provideFormatter = true;
                format.enable = true;
                json.validate.enable = true;
              };
            };
          };

          languages = {
            nix = {
              servers = [ "nil" ];
              formatter = {
                command = lib.getExe pkgs.nixfmt;
                arguments = [
                  "--filename"
                  "%{buffer_name}"
                ];
              };
            };

            bash = {
              servers = [ "bash-language-server" ];
              formatter.command = lib.getExe pkgs.shfmt;
            };

            toml.servers = [ "taplo" ];

            yaml = {
              servers = [ "yaml-language-server" ];
              formatter = {
                command = lib.getExe pkgs.prettier;
                arguments = [
                  "--config"
                  (builtins.toString prettierConfig)
                  "--parser"
                  "yaml"
                ];
              };
            };

            json = {
              servers = [ "vscode-json-language-server" ];
              formatter = {
                command = lib.getExe pkgs.prettier;
                arguments = [
                  "--config"
                  (builtins.toString prettierConfig)
                  "--parser"
                  "json"
                ];
              };
            };

            markdown = {
              servers = [ "marksman" ];
              formatter = {
                command = lib.getExe pkgs.prettier;
                arguments = [
                  "--config"
                  (builtins.toString prettierConfig)
                  "--parser"
                  "markdown"
                ];
              };
            };

            xml.formatter = {
              command = lib.getExe pkgs.html-tidy;
              arguments = [
                "-xml"
                "-i"
              ];
            };

            nu.servers = [ "nu-lsp" ];
          };
        };

        cli.commands = {
          detect = {
            description = "Detect hardware and save the facter report.";
            packages = [
              pkgs.coreutils
              pkgs.nixos-facter
              prettierWrapped
            ];
            commands = ''
              mkdir -p assets/hardware
              sudo nixos-facter | prettier --parser json > "assets/hardware/$(hostname).json"
            '';
          };

          rebuild = {
            description = "Rebuild the current machine (report|switch|boot).";
            packages = [
              pkgs.coreutils
              pkgs.nixos-rebuild
            ];
            commands = ''
              case "''${1:-}" in
                report) action=dry-build ;;
                switch|boot) action="$1" ;;
                *)
                  echo "usage: dev rebuild report|switch|boot" >&2
                  exit 1
                  ;;
              esac
              shift
              sudo nixos-rebuild "$action" --flake "$PWD#$(cat /etc/hostname)" "$@"
            '';
          };
        };

        format.formatters = {
          nixfmt = {
            packages = [ nixfmtWrapped ];
            command = lib.getExe nixfmtWrapped;
            includes = [ "*.nix" ];
          };

          prettier = {
            packages = [ prettierWrapped ];
            command = lib.getExe prettierWrapped;
            options = [
              "--write"
              "--config"
              (builtins.toString prettierConfig)
            ];
            includes = [
              "*.json"
              "*.md"
              "*.yaml"
              "*.yml"
            ];
            excludes = [
              "flake.lock"
              "CHANGELOG.md"
              "LICENSE.md"
            ];
          };
        };

        check.checks = {
          cspell = {
            packages = [ cspellWrapped ];
            commands = "cspell lint . --no-progress";
          };

          markdownlint = {
            packages = [ pkgs.markdownlint-cli ];
            commands = "markdownlint --config ${markdownlintConfig} --ignore-path .gitignore .";
          };

          markdown-link-check = {
            packages = [
              pkgs.fd
              pkgs.markdown-link-check
            ];
            commands = ''
              if [ -z "''${NIX_BUILD_TOP:-}" ]; then
                fd --glob '**/*.md' . -0 | xargs -0 -r markdown-link-check \
                  --config ${markdownLinkCheckConfig} \
                  --quiet
              fi
            '';
          };

          nix-diagnostics = {
            packages = [
              pkgs.findutils
              pkgs.nil
            ];
            commands = ''
              # NOTE: nil exits 0 on warnings, so any output is a failure
              output="$(find . -name '*.nix' -type f -print0 \
                | xargs -0 -r -n 1 nil diagnostics 2>&1)" || {
                printf '%s\n' "$output" >&2
                exit 1
              }
              if [ -n "$output" ]; then
                printf '%s\n' "$output" >&2
                exit 1
              fi
            '';
          };
        };

        git = {
          enable = true;
          ignore = {
            templates = [ "Nix" ];
            patterns = ''
              # Repository

              .env
            '';
          };
          attributes = "* text=auto eol=lf";
        };

        license = {
          enable = true;
          spdx = "MIT";
          source = ../../LICENSE.md;
          path = "LICENSE.md";
        };

        workflows = {
          check = {
            on.pull_request = { };
            installable = null;
            jobName = "check";
            cachix = {
              name = "haras";
              extraPullNames = null;
              authToken = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
            };
            steps = [
              { run = "nix flake check --show-trace --all-systems"; }
            ];
          };
        };
      };
  };
}
