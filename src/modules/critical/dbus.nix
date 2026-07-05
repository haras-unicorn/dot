{
  machines.nixosModules.dbus = {
    services.dbus.implementation = "broker";
  };
}
