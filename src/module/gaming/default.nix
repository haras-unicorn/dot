{ pkgs
  # , self
, ...
}:

# TODO: build lutris packages from yml here with `lutris --install`
# TODO: fix clashing nofile limits

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

      mono # NOTE: ascension wow
      gnome.zenity # NOTE: ascension wow
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
    home.packages = [
      (pkgs.dwarf-fortress-packages.dwarf-fortress-full.override {
        # Console
        enableIntro = false;
        enableTextMode = true;
        enableSound = false;

        # GUI
        # theme = pkgs.dwarf-fortress-packages.themes.obsidian;
        # enableStoneSense = true;
        # enableSoundSense = true;
        # enableDwarfTherapist = true;
        # enableLegendsBrowser = true;
        # enableTruetype = true;
      })
    ];
  };
}
