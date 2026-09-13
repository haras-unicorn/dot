{
  self.nixosModules.localtimed.value = {
    services.localtimed.enable = true;
  };
}
