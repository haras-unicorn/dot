{ ... }:

{
  branch.nixosModule.nixosModule = {
    services.cockroachdb.enable = true;
  };
}
