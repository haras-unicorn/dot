{ pkgs, config, system, ... }:

# FIXME: vscodium doesn't work (on wayland)?

# TODO: add needed extensions to nixpkgs

{
  shell.aliases = {
    code = "${pkgs."${config.dot.visual.pkg}"}/bin/${config.dot.visual.bin}";
  };

  programs.vscode.enable = true;
  programs.vscode.package = pkgs."${config.dot.visual.pkg}";
  programs.vscode.keybindings = (builtins.fromJSON (builtins.readFile ./keybindings.json));
  programs.vscode.userSettings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    "editor.fontFamily" = ''"${config.dot.font.nerd.name}"'';
    "debug.console.fontFamily" = ''"${config.dot.font.nerd.name}"'';
    "terminal.integrated.fontFamily" = ''"${config.dot.font.nerd.name}"'';
    "editor.fontSize" = "${builtins.toString (config.dot.font.size.medium + 1)}";
    "debug.console.fontSize" = "${builtins.toString (config.dot.font.size.small + 1)}";
    "terminal.integrated.fontSize" = "${builtins.toString (config.dot.font.size.small + 1)}";
    "terminal.external.linuxExec" = "${pkgs."${config.dot.term.pkg}"}/bin/${config.dot.term.bin}";
    "terminal.integrated.profiles.linux" = {
      "${config.dot.shell.module}" = {
        "path" = "${pkgs."${config.dot.shell.pkg}"}/bin/${config.dot.shell.bin}";
      };
      "bash" = {
        "path" = "${pkgs.bashInteractiveFHS}/bin/bash";
        "icon" = "terminal-bash";
      };
    };
    "terminal.integrated.defaultProfile.linux" = "${config.dot.shell.module}";
    "terminal.integrated.automationProfile.linux" = {
      "path" = "${pkgs.bashInteractiveFHS}/bin/bash";
    };
  };

  programs.vscode.enableExtensionUpdateCheck = false;
  programs.vscode.enableUpdateCheck = false;
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.extensions = builtins.filter
    (extension: extension != null)
    (builtins.map
      (extension:
        if builtins.hasAttr "platforms" extension.src && (! builtins.hasAttr "${system}" extension.src.platforms)
        then null
        else
          (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
            vsix = builtins.fetchurl
              (if builtins.hasAttr "platforms" extension.src
              then ({ inherit (extension.src) name; } // extension.src.platforms.${system})
              else extension.src);
            mktplcRef = { inherit (extension) name publisher version; };
          }))
      (builtins.fromJSON (builtins.readFile ./extensions.json)));
}
