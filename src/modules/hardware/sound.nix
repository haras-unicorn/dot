{ inputs, ... }:

{
  self.nixosModules.sound.value =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.dot.user.user;

      hardware = config.dot.hardware;
    in
    {
      imports = [ inputs.musnix.nixosModules.musnix ];

      options.dot = {
        sound = {
          pipewire = lib.mkOption {
            type = lib.types.package;
            internal = true;
          };
        };
      };

      config = lib.mkIf hardware.sound {
        dot.sound.pipewire = config.services.pipewire.package;

        services.pulseaudio.package = pkgs.pulseaudioFull;

        services.pipewire.enable = true;
        services.pipewire.wireplumber.enable = true;
        services.pipewire.alsa.enable = true;
        services.pipewire.alsa.support32Bit = true;
        services.pipewire.jack.enable = true;
        services.pipewire.pulse.enable = true;

        users.users.${user}.extraGroups = [
          "audio"
        ];

        security.rtkit.enable = lib.mkIf (!hardware.battery) true;
        musnix.enable = lib.mkIf (!hardware.battery) true;
      };
    };

  self.homeModules.sound.value =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.sound {
      dot.desktop.volume = lib.mkMerge [
        (lib.mkIf hardware.browser (lib.getExe pkgs.pwvucontrol))
        (lib.mkIf (!hardware.browser && hardware.editor) (lib.getExe pkgs.wiremix))
      ];

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "com.saivert.pwvucontrol";
        }
      ];

      home.packages = lib.mkMerge [
        (lib.mkIf hardware.browser [
          pkgs.pwvucontrol
          pkgs.crosspipe
        ])
        (lib.mkIf (!hardware.browser && hardware.editor) [
          pkgs.wiremix
        ])
      ];
    };
}
