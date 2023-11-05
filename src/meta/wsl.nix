{ lib, ... }:

with lib;
{
  options.dot.wsl = mkOption {
    type = with types; bool;
    default = false;
    example = true;
  };

  config = { };
}
