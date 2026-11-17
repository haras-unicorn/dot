{
  self.nixpkgs.config.allowUnfreePackageNames = [ "minecraft-server" ];

  self.homeModules.minecraft.value =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      programs.prismlauncher = {
        enable = true;
        settings = {
          # Prism otherwise picks the first Java it detects, which was 1.8,
          # and Minecraft 26.x needs 25
          JavaPath = "${pkgs.jdk25}/bin/java";
        };
      };
    };

  self.nixosModules.minecraft.value =
    {
      config,
      lib,
      unstablePkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;

      interface = "minecraft";
      port = 25565;
    in
    lib.mkIf hardware.gaming {
      services.minecraft-server = {
        enable = true;
        package = unstablePkgs.minecraftServers.vanilla-26-3;
        eula = true;
        declarative = true;
        serverProperties = {
          motd = "dot minecraft server";
          level-name = "dot";
          server-port = port;
          white-list = false;
        };
      };

      services.easytier = {
        enable = true;
        instances.minecraft = {
          enable = true;
          environmentFiles = [ "/etc/easytier/minecraft/.env" ];
          settings = {
            dhcp = true;
            hostname = config.networking.hostName;
          };
          extraSettings.flags = {
            accept_dns = true;
            dev_name = interface;
            private_mode = true;
          };
        };
      };

      networking.firewall.interfaces.${interface}.allowedTCPPorts = [ port ];

      stolon.keep.directories = [
        "/etc/easytier"
      ];
    };
}
