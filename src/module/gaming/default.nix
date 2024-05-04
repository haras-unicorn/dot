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
        # theme = pkgs.dwarf-fortress-packages.themes.obsidian;
        # enableIntro = false;
        # enableStoneSense = true;
        # enableSoundSense = true;
        # enableDwarfTherapist = true;
        # enableLegendsBrowser = true;
        # enableTruetype = true;
        enableTextMode = true;
        enableSound = false;
      })
    ];
  };
}
