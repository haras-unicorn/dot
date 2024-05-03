# dot modules come in two forms: function and object

# Function modules take input args from nixpkgs.lib.nixosSystem and home-manager module parameters
# Object modules are like function modules but don't take any parameters

# The schema closely follows nixpkgs.lib.nixosSystem module schema
# Each module can import other modules and can declare options directly or be separated into config and options parts

# Each module config has a shared, system and home part

# The system part is applied to nixpkgs.lib.nixosSystem
# The home part is applied to home manager

# The home part also has a shared part and a per-user part
# The shared part is applied to each user via home-manager.sharedModules
# The per-user part is applied to individual users (not yet implemented)

# The shared part applies to both nixpkgs.lib.nixosSystem and home-manager.sharedModules

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
#   imports = [ "${self}/src/modules/waybar" ];
#   options = {
#     dot = {
#       desktopEnvironment.sessionVariables = lib.mkOption {
#         type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
#         default = { };
#         example = { EDITOR = "hx"; };
#         description = ''
#           Environment variables to set on session start with Hyprland.
#         '';
#       };
#     };
#   };
#   config = {
#     system = {
#       programs.hyprland.enable = true;
#       programs.hyprland.xwayland.enable = true;
#     };
#     home.shared = {
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
      let
        imported =
          if (builtins.isPath maybeImport) || (builtins.isString maybeImport)
          then import maybeImport
          else maybeImport;
      in
      (mkModule (imported)) specialArgs)
    (if builtins.hasAttr "imports" dotObject
    then dotObject.imports
    else [ ]);
  mkOptions = specialArgs: dotObject:
    if builtins.hasAttr "options" dotObject
    then dotObject.options
    else { };
  mkConfig = { lib, ... }: path: dotObject:
    if builtins.hasAttr "config" dotObject
    then
      let
        configObject = dotObject.config;
      in
      if lib.hasAttrByPath path configObject
      then lib.getAttrByPath path configObject
      else { }
    else dotObject;
  concatModules = specialArgs: modules: {
    imports = builtins.foldl'
      (acc: next: acc ++ [{ options = next.options; config = next.config; }])
      [ ]
      modules;
  };
in
rec {
  definedUsers = dotModule: { lib, ... } @specialArgs:
    let
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports definedUsers specialArgs dotObject;
      config = mkConfig specialArgs [ "home" ] dotObject;
    in
    lib.lists.unique (
      lib.lists.flatten (
        imports
        ++ (builtins.filter
          (user: user != "shared")
          (builtins.attrNames config))
      ));

  mkSystemModule = dotModule: specialArgs:
    let
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports mkSystemModule specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs [ "system" ] dotObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] dotObject;
    in
    concatModules specialArgs (imports ++ [
      { inherit options config; }
      { config = sharedConfig; }
    ]);

  mkHomeSharedModule = dotModule: specialArgs:
    let
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports mkHomeSharedModule specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs [ "home" "shared" ] dotObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] dotObject;
    in
    concatModules specialArgs (imports ++ [
      { inherit options config; }
      { config = sharedConfig; }
    ]);

  mkHomeUserModule = userName: dotModule: rawspecialArgs:
    let
      specialArgs = rawspecialArgs // { inherit userName; };
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports (mkHomeUserModule userName) specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs [ "home" userName ] dotObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] dotObject;
    in
    concatModules specialArgs (imports ++ [
      { inherit options config; }
      { config = sharedConfig; }
    ]);
}
