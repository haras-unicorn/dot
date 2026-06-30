{
  machines.nixosModules.pinentry =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      dot.programs.pinentry.package =
        if hardware.graphics then pkgs.pinentry-qt else pkgs.pinentry-curses;
    };
}
