{ inputs, ... }:

{
  libAttrs.host.modules.home.home =
    { lib, config, ... }:
    {
      imports = [
        inputs.nur.modules.homeManager.default
        inputs.nix-index-database.homeModules.nix-index
        inputs.nixos-facter-modules.hmModules.facter
        inputs.sops-nix.homeManagerModules.sops
      ];

      home.stateVersion = config.dot.host.version;

      home.username = config.dot.host.user;
      home.homeDirectory = "/home/${config.dot.host.user}";

      facter.reportPath = config.dot.host.hardware;

      sops.defaultSopsFile = config.dot.host.secrets;
      sops.age.keyFile = "/root/host.scrt.key";
    };
}
