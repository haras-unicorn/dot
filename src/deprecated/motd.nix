{
  self.lib.deprecated.nixosModules.motd =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      user = config.dot.user.user;
      host = config.networking.hostName;

      dot = builtins.replaceStrings [ "\n" ] [ "\\n" ] ''
         ____   ___ _____
        |  _ \ / _ \_   _|
        | | | | | | || |
        | | | | | | || |
        | |_| | |_| || |_
        |____/ \___/_____|
      '';

      banner = pkgs.writeShellApplication {
        name = "motd-banner";
        runtimeInputs = [
          pkgs.curl
          pkgs.jq
        ];
        text = ''
          printf "${dot}\n"
          printf "Welcome to ${host}, ${user}~ <3\n"
        '';
      };
    in
    {
      programs.rust-motd.enable = true;
      programs.rust-motd.enableMotdInSSHD = true;
      programs.rust-motd.settings = {
        global.version = "1.0";
        last_run = { };
        uptime = {
          prefix = "Uptime";
        };
        last_login = {
          ${user} = 3;
        };
        service_status = {
          SSH = "sshd";
        };
        banner = {
          color = "red";
          command = lib.getExe banner;
        };
      };

      services.openssh.settings.PrintMotd = true;

      users.motdFile = "/var/lib/rust-motd/motd";
    };

  self.lib.deprecated.homeModules.motd =
    { pkgs, ... }:
    let
      motd-wrap = pkgs.writeShellApplication {
        name = "motd-wrap";
        text = ''
          cat /var/lib/rust-motd/motd
          exec "$@"
        '';
      };
    in
    {
      home.packages = [
        motd-wrap
      ];
    };
}
