{ lib, ... }:

with lib;
{
  options.dot.location = {
    timeZone = mkOption {
      type = with types; str;
      default = "Etc/UTC";
      example = "Etc/UTC";
    };
  };

  config = { };
}
