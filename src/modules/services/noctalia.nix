{ inputs, ... }:

# NOTE: https://github.com/nix-community/stylix/commit/831414670d6b5b3aebb99e5ee6d3dac73f2a3f02
# TODO: remove theme stuff if/when it lands in nixpkgs stable

{
  machines.homeModules.noctalia =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = config.programs.noctalia.package;

      colors = config.lib.stylix.colors.withHashtag;
      fonts = config.stylix.fonts;
      opacity = config.stylix.opacity;
      polarity = if config.stylix.polarity == "dark" then "dark" else "light";
      wallpaper = config.stylix.image;
      theme = "stylix";
      margin = 8;
      spacing = margin * 2;
      thickness = margin * 3;

      makeCommand =
        name: text:
        pkgs.writeShellApplication {
          name = "noctalia-${name}";
          runtimeInputs = [ package ];
          text = ''exec noctalia ${text} "$@"'';
        };
    in
    {
      imports = [ inputs.noctalia.homeModules.default ];

      config = lib.mkIf (hardware.visual && hardware.wayland) {
        dot.programs.shell = {
          launcher = makeCommand "launcher" "msg panel-toggle launcher";
          emoji = makeCommand "emoji" "msg panel-toggle launcher /emo";
          dmenu = makeCommand "dmenu" "dmenu";
          screenshot = makeCommand "screenshot" "msg screenshot-fullscreen pick";
          regionshot = makeCommand "screenshot" "msg screenshot-region";
          volume-up = makeCommand "volume-up" "msg volume-up";
          volume-down = makeCommand "volume-down" "msg volume-down";
          volume-mute-unmute = makeCommand "volume-mute-unmute" "msg volume-mute";
          brightness-up = makeCommand "brightness-up" "msg brightness-up";
          brightness-down = makeCommand "brightness-down" "msg brightness-down";
        };

        programs.noctalia = {
          enable = true;
          systemd.enable = true;
          settings = {
            shell = {
              setup_wizard_enabled = false;
              external_ip_enabled = true;
              polkit_agent = false;
              avatar_path = osConfig.dot.profile.image;
              panel = {
                transparency_mode = "soft";
                floating_offset = margin;
              };
              screenshot = {
                filename_pattern = "%Y-%m-%d_%H-%M-%S";
                directory = "${config.xdg.userDirs.pictures}/screenshots";
                copy_to_clipboard = true;
              };
            };

            bar.main = {
              thickness = thickness;
              margin_ends = margin;
              margin_edge = margin;
              margin_opposite_edge = margin;
              padding = spacing;
              position = "top";
              widget_spacing = spacing;
              start = [
                "control-center"
                "settings"
                "gap"
                "launcher"
                "screenshot"
                "gap"
                "media"
                "volume"
                "gap"
                "battery"
                "power_profile"
                "brightness"
                "nightlight"
                "weather"
                "gap"
                "keyboard_layout"
                "lock_keys"
                "gap"
                "workspaces"
              ];
              center = [ "clock" ];
              end = [
                "tray"
                "gap"
                "monitor"
                "gap"
                "network"
                "bluetooth"
                "gap"
                "privacy"
                "caffeine"
                "notifications"
                "gap"
                "session"
              ];
            };

            widget = {
              gap = {
                type = "spacer";
                length = thickness;
              };
              privacy = {
                type = "privacy";
                icon_spacing = spacing;
                mic_filter_regex = "^easyeffects$";
              };
              monitor = {
                type = "sysmon";
                stat = "cpu_usage";
                network_speed_compact = true;
                interface = hardware.interface;
              };
            };

            idle = {
              behavior = {
                lock = {
                  action = "lock";
                  timeout = 180;
                  enabled = true;
                };
                screen-off = {
                  action = "screen_off";
                  timeout = 300;
                  enabled = true;
                };
                suspend = {
                  action = "lock_and_suspend";
                  timeout = 900;
                  enabled = true;
                };
              };
            };

            notification = {
              enable_daemon = true;
              position = "bottom_right";
              offset_x = spacing;
              offset_y = margin;
            };

            dock = {
              enabled = true;
              position = "bottom";
              auto_hide = true;
              reserve_space = false;
            };

            lockscreen = {
              blurred_desktop = true;
            };

            location.address = osConfig.dot.location.address;

            backdrop.enabled = true;
          };

          customPalettes.${theme}.${polarity} = with colors; {
            mPrimary = base0D;
            mOnPrimary = base00;
            mSecondary = base0E;
            mOnSecondary = base00;
            mTertiary = base0C;
            mOnTertiary = base00;
            mError = base08;
            mOnError = base00;
            mSurface = base00;
            mOnSurface = base05;
            mHover = base0C;
            mOnHover = base00;
            mSurfaceVariant = base01;
            mOnSurfaceVariant = base04;
            mOutline = base03;
            mShadow = base00;
            terminal = {
              foreground = base05;
              background = base00;
              cursor = base05;
              cursorText = base00;
              selectionFg = base05;
              selectionBg = base02;
              normal = {
                black = base00;
                red = base08;
                green = base0B;
                yellow = base0A;
                blue = base0D;
                magenta = base0E;
                cyan = base0C;
                white = base05;
              };
              bright = {
                black = base03;
                red = base08;
                green = base0B;
                yellow = base0A;
                blue = base0D;
                magenta = base0E;
                cyan = base0C;
                white = base07;
              };
            };
          };
          settings = {
            shell.font_family = fonts.sansSerif.name;
            theme = {
              mode = polarity;
              source = "custom";
              custom_palette = theme;
            };
            bar.main.background_opacity = opacity.desktop;
            dock.background_opacity = opacity.desktop;
            notification.background_opacity = opacity.popups;
            osd.background_opacity = opacity.popups;
            wallpaper = {
              enabled = true;
              default.path = wallpaper;
            };
          };
        };

        # NOTE: noctalia tells systemd it started too early
        # breaking qt apps that want systray
        systemd.user.services.noctalia-tray-ready = {
          Install.WantedBy = [
            "tray.target"
            "graphical-session.target"
          ];
          Unit = {
            Description = "Wait for noctalia tray to become ready";
            PartOf = [
              "graphical-session.target"
              "tray.target"
            ];
            Requires = [ "noctalia.service" ];
            After = [
              "noctalia.service"
              "graphical-session.target"
            ];
            Before = [ "tray.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutStartSec = 30;
            ExecStart = lib.getExe (
              pkgs.writeShellApplication {
                name = "wait-for-noctalia-tray";
                text = ''
                  while ! ${lib.getExe package} msg status \
                    | grep -q '"barVisible": true'; do
                    sleep 0.1
                  done
                  sleep 1
                '';
              }
            );
          };
        };

        # NOTE: https://github.com/noctalia-dev/noctalia-docs/blob/cec177a6b9bf928d148a669c6979cd0f62da0757/src/content/docs/v5/compositor-settings/niri.mdx
        programs.noctalia.settings.shell.niri_overview_type_to_launch_enabled = true;
        xdg.configFile."niri/config.kdl".text = ''
          debug {
            honor-xdg-activation-with-invalid-serial
          }

          layer-rule {
            match namespace="^noctalia-backdrop"
            place-within-backdrop true
          }

          layer-rule {
            match namespace="^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"
            background-effect {
              xray false
            }
          }
        '';

        dot.desktop.windowrules = [
          {
            rule = "float";
            selector = "class";
            arg = "dev.noctalia.Noctalia";
          }
        ];
      };
    };
}
