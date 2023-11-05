{ lib, ... }:

with lib;
{
  options.dot.user = {
    groups = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "libvirtd" "docker" "podman" "video" "audio" ];
    };
    shell = {
      pkg = mkOption {
        type = with types; str;
        default = "bash";
        example = "nushell";
      };
      bin = mkOption {
        type = with types; str;
        default = "bash";
        example = "nu";
      };
      module = mkOption {
        type = with types; str;
        default = "bash";
        example = "nushell";
      };
    };
  };

  config = { };
}
