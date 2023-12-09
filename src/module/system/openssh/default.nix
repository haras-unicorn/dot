{ ... }:

{
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  services.openssh.PermitRootLogin = "no";
  services.openssh.PasswordAuthentication = false;
}
