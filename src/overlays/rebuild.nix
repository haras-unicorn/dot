{ selfLib, ... }:

{
  self.overlays.overlays.rebuild.value =
    final: _prev:
    let
      system = final.stdenv.hostPlatform.system;

      path = selfLib.source.flake;
    in
    {
      rebuild = final.writeShellApplication {
        name = "rebuild";
        text = ''
          host="$(< /etc/hostname)"
          sudo nixos-rebuild switch \
            --flake "${path}#$host-${system}" \
            --option eval-cache false \
            "$@"
        '';
      };

      rebuild-trace = final.writeShellApplication {
        name = "rebuild-trace";
        text = ''
          host="$(< /etc/hostname)"
          sudo nixos-rebuild switch \
            --flake "${path}#$host-${system}" \
            --show-trace \
            --option eval-cache false \
            "$@"
        '';
      };

      rebuild-chroot = final.writeShellApplication {
        name = "rebuild-chroot";
        text = ''
          host="$(< /etc/hostname)"
          sudo nixos-rebuild switch \
            --flake "${path}#$host-${system}" \
            --option sandbox false \
            --option filter-syscalls false \
            --option eval-cache false \
            "$@"
        '';
      };
    };
}
