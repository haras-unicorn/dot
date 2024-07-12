{ pkgs, ... }:

# FIXME: azure extension add fails with some pip error

{
  home.shared = {
    home.packages = with pkgs; [
      (azure-cli.withExtensions [
        (pkgs.mkAzExtension rec {
          pname = "ssh";
          version = "2.0.4";
          url = "https://azcliprod.blob.core.windows.net/cli-extensions/ssh-${version}-py3-none-any.whl";
          sha256 = "";
          description = "SSH into Azure VMs using RBAC and AAD OpenSSH Certificates";
        })
      ])
    ];

    home.file.".azure/config".source = ./azure-config;
  };
}
