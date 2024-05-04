{ lib, pkgs, config, ... }:

let
  cfg = config.dot.editor;
in
{
  home.shared = {
    programs.lulezojne.config.plop = [
      {
        template = builtins.readFile ./lulezojne.toml;
        "in" = "${config.xdg.configHome}/helix/themes/lulezojne.toml";
        "then" = {
          command = "pkill";
          args = [ "--signal" "SIGUSR1" "hx" ];
        };
      }
    ];

    programs.helix.enable = true;
    programs.helix.package =
      (p: yes: no: lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ])
        (cfg.bin == "hx")
        cfg.package
        pkgs.nushell;

    programs.helix.settings = builtins.fromTOML (builtins.readFile ./config.toml);

    programs.helix.languages = {
      language-server = {
        nil = { command = "${pkgs.nil}/bin/nil"; };
      };
    };
  };
}
