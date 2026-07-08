{ selfLib, ... }:

{
  machines.homeModules.rebuild =
    {
      pkgs,
      config,
      osConfig,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      path = selfLib.source.flake;

      rebuild = pkgs.writeShellApplication {
        name = "rebuild";
        text = ''
          sudo nixos-rebuild switch \
            --flake "${path}#${osConfig.networking.hostName}-${system}" \
            --option eval-cache false \
            "$@"
        '';
      };

      rebuild-trace = pkgs.writeShellApplication {
        name = "rebuild-trace";
        text = ''
          sudo nixos-rebuild switch \
            --flake "${path}#${osConfig.networking.hostName}-${system}" \
            --show-trace \
            --option eval-cache false \
            "$@"
        '';
      };

      rebuild-chroot = pkgs.writeShellApplication {
        name = "rebuild-chroot";
        text = ''
          sudo nixos-rebuild switch \
            --flake "${path}#${osConfig.networking.hostName}-${system}" \
            --option sandbox false \
            --option filter-syscalls false \
            --option eval-cache false \
            "$@"
        '';
      };
    in
    {
      home.packages = [
        rebuild
        rebuild-trace
        rebuild-chroot
      ];
    };
}
