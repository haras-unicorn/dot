{
  libAttrs.nushell.mkNushellApplication =
    pkgs:
    {
      name,
      runtimeInputs ? [ ],
      text ? "",
    }:
    let
      path = builtins.concatStringsSep "\n  " (builtins.map (input: "`${input}/bin`") runtimeInputs);

      wrapped = pkgs.writeText "${name}-wrapped.nu" ''
        #!${pkgs.lib.getExe pkgs.nushell}

        $env.PATH ++= [
          ${path}
        ]

        ${text}
      '';
    in
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.nushell ];
      }
      ''
        nu --commands "nu-check --debug ${wrapped}"
        mkdir -p $out/bin
        cp ${wrapped} $out/bin/${name}
        chmod +x $out/bin/${name}
      '';
}
