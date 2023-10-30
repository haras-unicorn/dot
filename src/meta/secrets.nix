{ lib, ... }:

with lib;
{
  options.dot.secrets = mkOption {
    type = with types; boolean;
    default = false;
    example = true;
  };

  config = { };
}
