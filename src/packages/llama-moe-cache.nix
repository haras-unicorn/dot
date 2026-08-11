{ inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      makePackage =
        {
          config ? { },
          override ? { },
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            }
            // config;
          };

          src = pkgs.fetchFromGitHub {
            owner = "ongunm";
            repo = "llama-moe-cache";
            rev = "77c8767d26bd6285b2fe351c58143ee4d6b72fa6";
            hash = "sha256-5sAd5aSmC926ND1IZY5FtkAjRcJCvSzlJHTXJk+jjj8=";
          };

          scope = pkgs.callPackage "${src}/.devops/nix/scope.nix" { };
        in
        scope.llama-cpp.override override;
    in
    {
      packages = {
        llama-moe-cache = makePackage { };
        llama-moe-cache-cuda = makePackage {
          config = {
            cudaSupport = true;
          };
        };
        llama-moe-cache-rocm = makePackage {
          config = {
            rocmSupport = true;
          };
        };
        llama-moe-cache-vulkan = makePackage {
          override = {
            useVulkan = true;
          };
        };
      };
    };
}
