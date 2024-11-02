{ ... }:

{
  system = {
    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = true;
    services.openssh.settings.KbdInteractiveAuthentication = false;
  };
}
