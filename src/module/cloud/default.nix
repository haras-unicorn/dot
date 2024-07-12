{ pkgs, ... }:

# FIXME: azure extension add fails with some pip error

let
  # NOTE: https://github.com/NixOS/nixpkgs/blob/feb2849fdeb70028c70d73b848214b00d324a497/pkgs/tools/admin/azure-cli/default.nix#L41
  mkAzExtension =
    { pname
    , version
    , url
    , sha256
    , description
    , ...
    }@args: pkgs.python311Packages.buildPythonPackage ({
      format = "wheel";
      src = builtins.fetchurl { inherit url sha256; };
      meta = {
        inherit description;
        inherit (pkgs.azure-cli.meta) platforms maintainers;
        homepage = "https://github.com/Azure/azure-cli-extensions";
        changelog = "https://github.com/Azure/azure-cli-extensions/blob/main/src/${pname}/HISTORY.rst";
        license = pkgs.lib.licenses.mit;
        sourceProvenance = [ pkgs.lib.sourceTypes.fromSource ];
      } // args.meta or { };
    } // (removeAttrs args [ "url" "sha256" "description" "meta" ]));
in
{
  home.shared = {
    home.packages = with pkgs; [
      (azure-cli.withExtensions [
        (mkAzExtension rec {
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
