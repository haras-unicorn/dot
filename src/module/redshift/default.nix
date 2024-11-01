{ ... }:

{
  home = {
    services.redshift.enable = true;
    services.redshift.provider = "geoclue2";
  };
}
