{ pkgs, ... }:

{
  home.shared = {
    services.swayidle.enable = true;
    services.swayidle.timeouts = [
      {
        timeout = 60;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        timeout = 600;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];
  };
}
