{ inputs, ... }:

{
  perSystem =
    { system, ... }:
    let
      cudaPkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      llama-moe-cache-cuda = cudaPkgs.llama-cpp.overrideAttrs {
        version = "10362";
        src = cudaPkgs.fetchFromGitHub {
          owner = "haras-unicorn";
          repo = "llama.cpp";
          rev = "4f3701bc44ec7e51b5401593c6269b8cc694fe28";
          hash = "";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      };
    in
    {
      packages.llama-moe-cache-cuda = llama-moe-cache-cuda;
    };
}
