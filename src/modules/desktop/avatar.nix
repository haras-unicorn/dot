{ self, ... }:

{
  machines.nixosModules.avatar = { config, ... }: {
    dot.user = {
      user = "haras";
      group = "haras";
      image = "${self}/assets/profile/avatar.png";
    };

    systemd.tmpfiles.rules = [
      "L+ /var/lib/AccountsService/icons/${config.dot.user.user} - - - - ${config.dot.user.image}"
    ];
  };
}
