{
  perSystem =
    { pkgs, ... }:
    {
      packages.llama-moe-cache-cuda = (pkgs.llama-cpp.override { cudaSupport = true; }).overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "haras-unicorn";
          repo = "llama.cpp";
          rev = "d7e9b46b3c052be760f4d2786a0fa16e8e7fb7a4";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      };
    };
}
