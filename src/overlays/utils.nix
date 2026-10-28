{ self, ... }:

{
  self.overlays.overlays.utils.value = final: _prev: {
    run-disowned = final.writeShellApplication {
      name = "run-disowned";
      text = ''
        "$@" &>/dev/null & disown %-
      '';
    };

    nix-run-nixpkgs = final.writeShellApplication {
      name = "nix-run-nixpkgs";
      text = ''
        name="$1"
        shift
        exec nix run "nixpkgs#$name" -- "$@"
      '';
    };

    nix-run-unstable = final.writeShellApplication {
      name = "nruu";
      text = ''
        name="$1"
        shift
        exec nix run --impure "github:nixos/nixpkgs/nixos-unstable#$name" -- "$@"
      '';
    };

    nix-unfree = final.writeShellApplication {
      name = "nix-unfree";
      text = ''
        export NIXPKGS_ALLOW_UNFREE=1
        exec "$@"
      '';
    };

    nix-fast = final.writeShellApplication {
      name = "nix-fast";
      text = ''
        export NIX_CONFIG="''${NIX_CONFIG:-}
        max-jobs = auto
        cores = 0"
        exec "$@"
      '';
    };

    nix-trace = final.writeShellApplication {
      name = "nix-trace";
      text = ''
        export NIX_CONFIG="''${NIX_CONFIG:-}
        show-trace = true"
        exec "$@"
      '';
    };

    dd-if-of = final.writeShellApplication {
      name = "dd-if-of";
      text = ''
        if="$1"
        of="$2"
        shift
        shift
        exec dd "if=$if" "of=$of" bs=4M conv=sync,noerror oflag=direct status=progress "$@"
      '';
    };
  };
}
