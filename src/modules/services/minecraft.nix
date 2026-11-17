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
      pkgs,
      unstablePkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;
      minecraft = config.services.minecraft-server;

      interface = "minecraft";
      port = 25565;
      serverAddress = "127.0.0.1";
      serverPort = 25566;

      minecraftDataDir = "/var/lib/minecraft";
      easytierConfigDir = "/etc/easytier";

      lazymcConfig = (pkgs.formats.toml { }).generate "lazymc.toml" {
        public.address = "0.0.0.0:${builtins.toString port}";
        server = {
          address = "${serverAddress}:${builtins.toString serverPort}";
          directory = minecraftDataDir;
          command = "${minecraft.package}/bin/minecraft-server ${minecraft.jvmOpts}";
          # Stop the server when idle, which frees its memory, and do not freeze it
          freeze_process = false;
          # Disable whitelist because the VPN is the security layer
          wake_whitelist = false;
        };
        # Sleep after 5 minutes and not the default of 1 minute
        time.sleep_after = 300;
        # The server properties are declarative, so lazymc must not edit them
        advanced.rewrite_server_properties = false;
        config.version = pkgs.lazymc.version;
      };
    in
    lib.mkIf hardware.gaming {
      # The unit runs lazymc, and lazymc starts the server as its child. Its
      # stop script writes to the stdin socket of the main process, which would
      # now be lazymc, so systemd stops the unit with SIGTERM instead
      systemd.services.minecraft-server.serviceConfig = {
        ExecStart = lib.mkForce "${lib.getExe pkgs.lazymc} --config ${lazymcConfig} start";
        ExecStop = lib.mkForce [ ];
      };

      services.minecraft-server = {
        enable = true;
        package = unstablePkgs.minecraftServers.vanilla-26-3;
        eula = true;
        dataDir = minecraftDataDir;
        declarative = true;
        serverProperties = {
          motd = "dot minecraft server";
          level-name = "dot";
          server-ip = serverAddress;
          server-port = serverPort;
          white-list = false;
        };
      };

      services.easytier = {
        enable = true;
        instances.minecraft = {
          enable = true;
          environmentFiles = [ "${easytierConfigDir}/minecraft/.env" ];
          settings = {
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
        minecraftDataDir
        easytierConfigDir
      ];
    };
}
