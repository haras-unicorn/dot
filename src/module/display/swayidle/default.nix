{ pkgs, ... }:

# FIXME: focused video not preventing locking

{
  home = {
    services.swayidle.enable = true;
    services.swayidle.timeouts = [
      {
        timeout = 60 * 5;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        timeout = 60 * 60;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];
  };
}
