{
  pkgs,
  config,
  ...
}:

let
  host = config.dot.host;

  system = pkgs.system;

  path = "github:haras-unicorn/dot";

  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        --option eval-cache false \
        "$@"
    '';
  };

  rebuild-trace = pkgs.writeShellApplication {
    name = "rebuild-trace";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        --show-trace \
        --option eval-cache false \
        "$@"
    '';
  };

  rebuild-chroot = pkgs.writeShellApplication {
    name = "rebuild-chroot";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        --option sandbox false \
        --option filter-syscalls false \
        --option eval-cache false \
        "$@"
    '';
  };
in
{
  homeManagerModule = {
    home.packages = [
      rebuild
      rebuild-trace
      rebuild-chroot
    ];
  };
}
