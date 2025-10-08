{ pkgs, config, ... }:

let
  user = config.dot.user;
  host = config.dot.host.name;

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
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      printf "${dot}\n"
      printf "Welcome to ${host}, ${user}~ <3\n"
    '';
  };

  motd-wrap = pkgs.writeShellApplication {
    name = "motd-wrap";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      cat /var/lib/rust-motd/motd
      exec "$@"
    '';
  };
in
{
  branch.nixosModule.nixosModule = {
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
        command = "${banner}/bin/motd-banner";
      };
    };

    services.openssh.settings.PrintMotd = true;

    users.motdFile = "/var/lib/rust-motd/motd";
  };

  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      motd-wrap
    ];
  };
}
