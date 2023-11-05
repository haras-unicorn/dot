{ self, pkgs, config, slick-fox, arkenfox-userjs, ... }:

# TODO: duckduckgo
# note that last time it was overwriting it

# NOTE: https://github.com/arkenfox/user.js/wiki
# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json

{
  imports = [
    "${self}/src/module/home/ffmpeg"
  ];

  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-bin;

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

  home.file.".mozilla/firefox/personal/chrome/userChrome.css".text = ''
    ${builtins.readFile "${slick-fox}/userChrome.css"}

    ${builtins.readFile ./user-overrides.css}
  '';

  home.file.".mozilla/firefox/personal/user.js".text = ''
    ${builtins.readFile "${arkenfox-userjs}/user.js"}

    ${builtins.readFile ./user-overrides.js}
  '';
}
