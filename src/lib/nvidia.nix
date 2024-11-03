{ nixpkgs, ... }:

let
  pkgs = import nixpkgs { };

  legacyHtml = pkgs.fetchurl {
    name = "nvidia-legacy-html";
    url = "https://web.archive.org/web/20240928225313/https://www.nvidia.com/en-us/drivers/unix/legacy-gpu/";
    hash = "";
  };

  legacyScript = pkgs.writeTextFile {
    name = "nvidia-legacy-script";
    text = ''
      $in
        | lines
        | where $it =~ 'td class="text"'
        | skip 3
        | str replace -r '<.*>(.*)</td>' '$1'
        | str trim
        | where { not ($in | is-empty) and (($in | split row ' ' | length) == 1) }
        | uniq
        | str join "\n" 
    '';
  };

  legacyText = pkgs.runCommand
    "nvidia-legacy-text"
    {
      buildInputs = [ pkgs.nushell ];
    }
    ''
      cat ${legacyHtml} | nu --stdin ${legacyScript}
    '';

  legacy = pkgs.lib.splitString "\n" (builtins.readFile legacyText);
in
{
  inherit legacy;
}
