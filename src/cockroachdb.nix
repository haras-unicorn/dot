{ ... }:

{
  integrate.nixosModule.nixosModule = {
    services.cockroachdb.enable = true;
  };
}
