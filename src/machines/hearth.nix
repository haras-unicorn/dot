{ self, selfLib, ... }:

{
  self.nixosConfigurations.hearth = {
    flake = true;

    value =
      { config, ... }:
      let
        audioBoxNode = "usb-PreSonus_AudioBox_USB_96_000000000000-00.analog-stereo";
        audioBoxDescription = "AudioBox USB 96 Analog Stereo";
      in
      {
        boot.blacklistedKernelModules = [
          "amdgpu"
          "radeon"
        ];

        dot.hardware.temperature = "/sys/class/hwmon/hwmon2/temp1_input";
        dot.hardware.display = "DP-1";

        dot.wallpaper.static = true;

        dot.location = selfLib.location;

        hardware.facter.hintsV1.graphics.cards.vramMap = {
          "PCI:1:0:0" = 12 * 1000 * 1000 * 1000;
          "PCI:12:0:0" = 512 * 1000 * 1000;
        };

        corm.gpu-provider.kind.strata = {
          cudaArchitectures = [ "86" ];
          extraArgs = [
            "--vram-reserve-mib"
            "2048"
          ];
        };

        dot.easyeffects.output.krk = {
          preset = "${self}/assets/easyeffects/hearth-krk.json";
          device = "alsa_output.${audioBoxNode}";
          route = "Analog Output";
          description = audioBoxDescription;
        };

        dot.easyeffects.output.redmi = {
          preset = "${self}/assets/easyeffects/hearth-redmi.json";
          device = "bluez_output.9C_49_52_87_9A_5B.1";
          route = "Headphones";
          description = "Redmi Buds 4 Lite";
        };

        dot.easyeffects.input.rode = {
          preset = "${self}/assets/easyeffects/hearth-rode.json";
          device = "alsa_input.${audioBoxNode}";
          route = "Analog Input";
          description = audioBoxDescription;
        };

        home-manager.users.${config.dot.user.user} = {
          xdg.configFile."obs-studio/basic/scenes/Untitled.json" = {
            force = true;
            source = "${self}/assets/obs/hearth-scene.json";
          };
        };
      };
  };
}
