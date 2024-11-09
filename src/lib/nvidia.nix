{ nixpkgs, ... }:

# TODO: fix 340

pkgs:

let
  openUrl = "https://web.archive.org/web/20241006015348/https://github.com/NVIDIA/open-gpu-kernel-modules";
  openHtml = pkgs.fetchurl {
    name = "nvidia-open-html";
    url = openUrl;
    hash = "sha256-OoaoXg/5pOpDHWJZ1ksshtSJceCyNzb6R71rpSkHsyA=";
  };
  legacyUrl = "https://web.archive.org/web/20240928225313/https://www.nvidia.com/en-us/drivers/unix/legacy-gpu";
  legacyHtml = pkgs.fetchurl {
    name = "nvidia-legacy-html";
    url = legacyUrl;
    hash = "sha256-1Ofa/ykwnupjmZwuO+KKV2zlwvwXk2j8txmJBW/5Pj0=";
  };

  mkLegacyScript = curr: prev: pkgs.writeTextFile {
    name = "nvidia-legacy-${curr}-script";
    text = ''
      $in
        | lines
        | skip until { |x| $x =~ "${curr}.xx" }
        | take until { |x| $x =~ "${prev}.xx" }
        | skip 12
        | drop 4
        | enumerate
        | where ($it.index mod 5) == 0
        | each { |x| $x.item }
        | str replace -r ".*<td.*>([0-9A-F]+).*</td>.*" "$1"
        | str join "\n"
    '';
  };
  openScript = pkgs.writeTextFile {
    name = "nvidia-open-script";
    text = ''
      $in
        | lines
        | where $it =~ "<td>([0-9A-F]+ ?){1,3}</td>"
        | str replace -r "<td>([0-9A-F]+).*</td>" "$1"
        | str join "\n"
    '';
  };
  mkExpr = name: html: script:
    pkgs.lib.splitString "\n"
      (builtins.readFile
        "${pkgs.runCommand
          "nvidia-${name}-text"
          {
            buildInputs = [ pkgs.nushell ];
          }
          ''
            mkdir $out
            cat ${html} | nu --stdin -c '${builtins.readFile script}' > $out/result
          ''}/result");

  # legacy340 = mkExpr "legacy-340" legacyHtml (mkLegacyScript "340" "304");
  legacy340 = [ ];
  legacy470 = mkExpr "legacy-470" legacyHtml (mkLegacyScript "470" "390");
  legacy390 = mkExpr "legacy-390" legacyHtml (mkLegacyScript "390" "340");
  open = mkExpr "open" openHtml openScript;
in
{
  inherit
    legacy340
    legacy390
    legacy470
    open
    ;

  legacy = builtins.concatLists [
    legacy340
    legacy390
    legacy470
  ];
}
