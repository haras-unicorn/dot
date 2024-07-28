{ pkgs
, config
  # , self
, ...
}:

# TODO: build lutris packages from yml here with `lutris --install`
# TODO: fix clashing nofile limits
# NOTE: steamtinkerlaunch https://www.reddit.com/r/NixOS/comments/12xbdpl/comment/jhjbdz8

{
  system = {
    environment.systemPackages = with pkgs; [
      wineWowPackages.waylandFull
      virglrenderer
      win-virtio
      lutris
      retroarch
      cartridges
      winetricks
      protontricks
      protonup-ng
      nexusmods-app
      steamtinkerlaunch

      mono # NOTE: ascension wow
      zenity # NOTE: ascension wow
      appimage-run # NOTE: ascension wow
    ];

    programs.steam.enable = true;

    users.groups.games = { };

    security.pam.loginLimits = [
      { domain = "@games"; item = "nofile"; type = "hard"; value = "524288"; }
      { domain = "@games"; item = "nofile"; type = "soft"; value = "524288"; }
    ];
  };

  home.shared = {
    home.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${config.xdg.dataHome}/steamcompat";
    };
    xdg.dataFile."steamcompat/SteamTinkerLaunch/steamtinkerlaunch".source =
      "${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch";

    home.packages = [
      (pkgs.dwarf-fortress-packages.dwarf-fortress-full.override {
        dfVersion = "0.47.05";

        # Console
        enableIntro = false;
        enableTextMode = true;
        enableSound = false;

        enableDFHack = false;
        enableTWBT = false;
        enableSoundSense = false;
        enableStoneSense = false;
        enableDwarfTherapist = false;
        enableLegendsBrowser = false;
        enableTruetype = false;
        theme = null;

        # GUI
        # theme = pkgs.dwarf-fortress-packages.themes.obsidian;
      })
    ];
  };
}
