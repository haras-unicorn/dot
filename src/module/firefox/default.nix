{ pkgs
, config
, lib
, firefox-gx
, arkenfox-userjs
, ...
}:

# TODO: duckduckgo - note that last time it was overwriting it
# TODO: openai login

# NOTE: https://github.com/arkenfox/user.js/wiki
# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json

let
  cfg = config.dot.browser;

  bootstrap = config.dot.colors.bootstrap;

  firefox-gx-updated = pkgs.runCommand "firefox-gx-updated" { } (
    let
      primary = bootstrap.primary.normal.hex;
      secondary = bootstrap.secondary.normal.hex;
      accent = bootstrap.accent.normal.hex;
      danger = bootstrap.danger.normal.hex;
      warning = bootstrap.warning.normal.hex;
      info = bootstrap.info.normal.hex;
      success = bootstrap.success.normal.hex;
      text = bootstrap.text.normal.hex;
      background = bootstrap.background.normal.hex;
    in
    ''
      cp -r ${firefox-gx}/chrome .
      chmod -R u+w chrome
      CSS="./chrome/components/ogx_root-personal.css"

      declare -A COLOR_MAPPING=(
        ["--fuchsia"]="${primary}"
        ["--blue"]="${secondary}"
        ["--aqua"]="${accent}"
        ["--cyan"]="${info}"
        ["--lightblue"]="${info}"
        ["--pink"]="${danger}"
        ["--purple"]="${danger}"
        ["--green"]="${success}"
        ["--lightgreen"]="${success}"
        ["--yellow"]="${text}"
        ["--orange"]="${warning}"
        ["--red"]="${danger}"
        ["--gray"]="${background}"
        ["--navyblue"]="${primary}"
      )

      for VAR_NAME in "''${!COLOR_MAPPING[@]}"; do
        COLOR_VALUE="''${COLOR_MAPPING[$VAR_NAME]}"
        sed -i "s|\(''${VAR_NAME}:\s*\)\(#\?[0-9A-Fa-f]\{6\}\)\(.*\);|\1''${COLOR_VALUE}\3;|g" "$CSS"
      done

      cp -f '${config.dot.wallpaper}' ./chrome/newtab/wallpaper-dark1.png

      mkdir -p $out
      cp -r chrome $out/
    ''
  );
in
{
  home.shared = {
    programs.firefox.enable = true;
    programs.firefox.package =
      (p: yes: no: lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ])
        (cfg.bin == "firefox")
        cfg.package
        pkgs.firefox;

    programs.firefox.profiles = {
      personal = {
        id = 0;
        name = "personal";
        isDefault = true;
        extensions = with config.nur.repos.rycee.firefox-addons; [
          ublock-origin
          darkreader
          vimium-c
          i-dont-care-about-cookies
        ];
      };
    };

    home.file.".mozilla/firefox/personal/chrome".source = "${firefox-gx-updated}/chrome";

    home.file.".mozilla/firefox/personal/user.js".text = ''
      ${builtins.readFile "${arkenfox-userjs}/user.js"}

      ${builtins.readFile ./user-overrides.js}
    '';
  };
}
