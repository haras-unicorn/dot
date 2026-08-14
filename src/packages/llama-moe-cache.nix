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
          rev = "03c4325d236f1c8cd91949ea330468bf8ff7e6b7";
          hash = "sha256-P7XYSrMdLF4asEpw3AiDWix4rmvWLpIWh4fQaOEmqLM=";
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
