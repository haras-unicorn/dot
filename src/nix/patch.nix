{
  libAttrs.nixpkgs.patch =
    pkgs:
    pkgs.applyPatches {
      src = pkgs.path;
      patches = [
        ./make-openssl-ca-bundle-overrideable.patch
      ];
    };
}
