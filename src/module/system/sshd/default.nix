{ ... }:

{
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;
}
