# dot modules come in two forms: function and object

# Function modules take input args from nixpkgs.lib.nixosSystem and home-manager module parameters
# Object modules are like function modules but don't take any parameters

# The schema closely follows nixpkgs.lib.nixosSystem module schema
# Each module can import other modules and can declare options directly or be separated into config and options parts

# Each module config has a shared, system and home part

# The system part is applied to nixpkgs.lib.nixosSystem
# The home part is applied to home manager

# The shared part applies to both nixpkgs.lib.nixosSystem and home-manager.sharedModules

# Option definitions are automatically prefixed with dot to prevent colisions

# Here is a kitchen sink example:
# { self, lib, config, ... }:
# let
#   cfg = config.dot.desktopEnvironment;
#   vars = lib.strings.concatStringsSep
#     "\n"
#     (builtins.map
#       (name: "env = ${name}, ${builtins.toString cfg.sessionVariables."${name}"}")
#       (builtins.attrNames cfg.sessionVariables));
# in
# {
#   imports = [ "${self}/src/module/waybar" ];
#   options = {
#     desktopEnvironment.sessionVariables = lib.mkOption {
#       type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
#       default = { };
#       example = { EDITOR = "hx"; };
#       description = ''
#         Environment variables to set on session start with Hyprland.
#       '';
#     };
#   };
#   config = {
#     system = {
#       programs.hyprland.enable = true;
#       programs.hyprland.xwayland.enable = true;
#     };
#     home = {
#       wayland.windowManager.hyprland.enable = true;
#       wayland.windowManager.hyprland.xwayland.enable = true;
#       wayland.windowManager.hyprland.extraConfig = ''
#         ${vars}
#       '';
#     };
#   };
# }

# This module aims to construct modules digestible by nixpkgs.lib.nixosSystem and
# home-manager from dot modules

let
  mkDotObject = specialArgs: dotModule:
    if builtins.isFunction dotModule
    then (dotModule specialArgs)
    else dotModule;
  mkImports = mkModule: specialArgs: dotObject: builtins.map
    (maybeImport:
      if (builtins.isPath maybeImport) || (builtins.isString maybeImport)
      then
        let
          module = (mkModule (import maybeImport) specialArgs);
        in
        if builtins.isAttrs module
        then module // { _file = maybeImport; }
        else module
      else mkModule maybeImport specialArgs)
    (if builtins.hasAttr "imports" dotObject
    then dotObject.imports
    else [ ]);
  mkOptions = specialArgs: dotObject:
    if builtins.hasAttr "options" dotObject
    then { dot = dotObject.options; }
    else { };
  mkConfig = { lib, ... }: path: dotObject:
    if builtins.hasAttr "config" dotObject
    then
      let
        configObject = dotObject.config;
      in
      if lib.hasAttrByPath path configObject
      then lib.getAttrFromPath path configObject
      else { }
    else
      if lib.hasAttrByPath path dotObject
      then lib.getAttrFromPath path dotObject
      else { };
in
rec {
  # NOTE: if pkgs here not demanded other modules don't get access...
  mkSystemModule = dotModule: { pkgs, ... } @specialArgs:
    let
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports mkSystemModule specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs [ "system" ] dotObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] dotObject;
    in
    {
      imports = imports ++ [ sharedConfig ];
      inherit options config;
    };

  mkHomeModule = dotModule: { pkgs, ... } @specialArgs:
    let
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports mkHomeModule specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs [ "home" ] dotObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] dotObject;
    in
    {
      imports = imports ++ [ sharedConfig ];
      inherit options config;
    };
}
