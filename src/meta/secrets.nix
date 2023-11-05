{ lib, ... }:

with lib;
{
  options.dot.secrets = mkOption {
    type = with types; bool;
    default = false;
    example = true;
  };

  config = { };
}
