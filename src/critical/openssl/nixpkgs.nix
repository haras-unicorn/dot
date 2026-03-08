{
  flake.nixosModules.critical-openssl-nixpkgs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.security.pki;
    in
    {
      options = {
        security.pki.certificatePaths = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          example = lib.literalExpression ''[ "/persist/certs/myca.crt" ]'';
          description = ''
            Extra CA cert files added during activation (merged with certificateFiles).
            Use for runtime-managed certs.
          '';
        };
        security.pki.buildOnActivation = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Build CA bundle during activation using merged certs.
            Overrides security.pki.installCACerts.
          '';
        };
      };

      config = lib.mkIf cfg.buildOnActivation {
        security.pki.installCACerts = lib.mkForce false;
        security.pki.caBundlePackage = lib.mkForce "/etc/ssl/certs/ca-bundle.crt";

        system.activationScripts.installCACerts = {
          deps = [ "setupSecrets" ];
          text =
            let
              allCertFiles = cfg.certificateFiles ++ cfg.certificatePaths;
              extraBundleFile = builtins.toFile "extra-certs.crt" (lib.concatStringsSep "\n" cfg.certificates);
              blocklistFile = builtins.toFile "blocklist.txt" (
                lib.concatStringsSep "\n" cfg.caCertificateBlacklist
              );
              bundleOutput = if cfg.useCompatibleBundle then "ca-no-trust-rules-bundle.crt" else "ca-bundle.crt";
            in
            ''
              echo "Building CA bundle..." >&2
              tmpdir=$(mktemp -d)
              trap 'rm -rf "$tmpdir"' EXIT

              extraBundle="$tmpdir/extra.crt"
              cat ${extraBundleFile} > "$extraBundle"
              ${lib.concatStringsSep "\n" (map (f: "cat ${f} >> \"$extraBundle\"") allCertFiles)}

              mkdir -p "$tmpdir/unbundled"
              mkdir -p "$tmpdir/hashed"
              ${pkgs.buildcatrust}/bin/buildcatrust \
                --certdata_input ${pkgs.cacert.src}/certdata.txt \
                --ca_bundle_input "$extraBundle" \
                --blocklist ${blocklistFile} \
                --ca_bundle_output "$tmpdir/ca-bundle.crt" \
                --ca_standard_bundle_output "$tmpdir/ca-no-trust-rules-bundle.crt" \
                --ca_unpacked_output "$tmpdir/unbundled" \
                --ca_hashed_unpacked_output "$tmpdir/hashed" \
                --p11kit_output "$tmpdir/ca-bundle.trust.p11-kit"
              echo "CA bundle successfully built..." >&2

              mkdir -p /etc/ssl/certs
              chmod 755 /etc/ssl/certs

              cp "$tmpdir/${bundleOutput}" "/etc/ssl/certs/${bundleOutput}.new"
              mv "/etc/ssl/certs/${bundleOutput}.new" "/etc/ssl/certs/ca-bundle.crt"
              chmod 644 "/etc/ssl/certs/ca-bundle.crt"

              ln -sf "/etc/ssl/certs/ca-bundle.crt" "/etc/ssl/certs/ca-certificates.crt"

              mkdir -p /etc/pki/tls/certs
              chmod 755 /etc/pki/tls/certs

              ln -sf "/etc/ssl/certs/ca-bundle.crt" "/etc/pki/tls/certs/ca-bundle.crt"

              mkdir -p /etc/ssl/trust-source
              chmod 755 /etc/ssl/trust-source

              cp "$tmpdir/ca-bundle.trust.p11-kit" "/etc/ssl/trust-source/ca-bundle.trust.p11-kit.new"
              mv "/etc/ssl/trust-source/ca-bundle.trust.p11-kit.new" "/etc/ssl/trust-source/ca-bundle.trust.p11-kit"
              chmod 644 "/etc/ssl/trust-source/ca-bundle.trust.p11-kit"

              echo "CA bundle successfully installed..." >&2
            '';
        };
      };
    };
}
