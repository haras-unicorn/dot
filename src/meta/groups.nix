{ lib, ... }:

with lib;
{
  options.dot.groups = mkOption {
    type = with types; listOf str;
    default = [ ];
    example = [ "libvirtd" "docker" "podman" "video" "audio" ];
  };

  config = { };
}
