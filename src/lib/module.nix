{ nixpkgs, ... }:

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
          path = maybeImport;
          module = (mkModule (import maybeImport) specialArgs);
        in
        if builtins.isAttrs module
        then module // { _file = path; }
        else module
      else
        let
          module = maybeImport;
        in
        mkModule module specialArgs)
    (if builtins.hasAttr "imports" dotObject
    then dotObject.imports
    else [ ]);

  mkOptions = specialArgs: dotObject:
    if builtins.hasAttr "disabled" dotObject
    then { }
    else if builtins.hasAttr "options" dotObject
    then { dot = dotObject.options; }
    else { };

  # TODO: when not containing config, use top level with stripped attrs
  mkConfig = specialArgs: dotObject:
    if builtins.hasAttr "disabled" dotObject
    then { }
    else if builtins.hasAttr "config" dotObject
    then { dot = dotObject.config; }
    else { };

  mkModule = path: dotObject:
    if builtins.hasAttr "disabled" dotObject
    then { }
    else if builtins.hasAttr "modules" dotObject
    then
      let
        moduleObject = dotObject.modules;
      in
      if nixpkgs.lib.hasAttrByPath path moduleObject
      then nixpkgs.lib.getAttrFromPath path moduleObject
      else { }
    else
      if nixpkgs.lib.hasAttrByPath path dotObject
      then nixpkgs.lib.getAttrFromPath path dotObject
      else { };

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkSystemModule = mkSystemModule: path: { pkgs, ... } @specialArgs:
    let
      dotModule = import path;
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports mkSystemModule specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs dotObject;
      module = mkModule [ "system" ] dotObject;
    in
    {
      imports = imports ++ [ module ];
      inherit config options;
      _file = path;
    };

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkHomeModule = mkHomeModule: path: { pkgs, ... } @specialArgs:
    let
      dotModule = import path;
      dotObject = mkDotObject specialArgs dotModule;
      imports = mkImports mkHomeModule specialArgs dotObject;
      options = mkOptions specialArgs dotObject;
      config = mkConfig specialArgs dotObject;
      module = mkModule [ "home" ] dotObject;
    in
    {
      imports = imports ++ [ module ];
      inherit options config;
      _file = path;
    };
in
{
  mkSystemModule = mkSystemModule mkSystemModule;
  mkHomeModule = mkHomeModule mkHomeModule;
}
