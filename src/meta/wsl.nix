{ lib, ... }:

with lib;
{
  options.dot.wsl = mkOption {
    type = with types; boolean;
    default = false;
    example = true;
  };

  config = { };
}
