{
  comin,
  config,
  pkgs,
  ...
}:

{
  nixosModule = {
    imports = [
      comin.nixosModules.comin
    ];

    services.comin = {
      enable = true;
      hostname = "${config.dot.host.name}-${pkgs.system}";
      remotes = [
        {
          name = "origin";
          url = "https://github.com/haras-unicorn/dot";
          branches.main.name = "main";
        }
      ];
    };
  };
}
