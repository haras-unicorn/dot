{
  perSystem =
    { pkgs, ... }:
    {
      packages.llama-moe-cache-cuda = (pkgs.llama-cpp.override { cudaSupport = true; }).overrideAttrs {
        version = "10362-fate";
        src = pkgs.fetchFromGitHub {
          owner = "haras-unicorn";
          repo = "llama.cpp";
          rev = "03c4325d236f1c8cd91949ea330468bf8ff7e6b7";
          hash = "sha256-zyu4oWrrrHSbvzfRZOgbx1YCGd5X3Lp6rMUfIDVUtfU=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      };
    };
}
