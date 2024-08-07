{ pkgs, ... }:

# TODO: fix clashing nofile limits

{
  system = {
    users.groups.development = { };

    boot.kernel.sysctl = {
      "fs.inotify.max_user_instances" = 65535;
    };

    security.pam.loginLimits = [
      { domain = "@development"; item = "nofile"; type = "hard"; value = "524288"; }
      { domain = "@development"; item = "nofile"; type = "soft"; value = "524288"; }
    ];

    networking.firewall.allowedTCPPorts = [
      5000
      5001
    ];
  };

  home = {
    shared = {
      home.packages = with pkgs; [
        gdb
        gdbgui
      ];
    };
  };
}
