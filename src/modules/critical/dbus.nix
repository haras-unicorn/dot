{
  self.nixosModules.dbus.value = {
    services.dbus.implementation = "broker";
    services.accounts-daemon.enable = true;
  };
}
