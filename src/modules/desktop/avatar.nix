{ self, ... }:

{
  machines.nixosModules.avatar = { config, ... }: {
    dot.profile = {
      image = "${self}/assets/profile/avatar.png";
    };

    systemd.tmpfiles.rules = [
      "L+ /var/lib/AccountsService/icons/${config.dot.user.user} - - - - ${config.dot.profile.image}"
    ];
  };
}
