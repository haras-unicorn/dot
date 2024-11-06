{ ... }:

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
    if builtins.hasAttr "disabled" dotObject
    then { }
    else if builtins.hasAttr "options" dotObject
    then { dot = dotObject.options; }
    else { };

  mkConfig = { lib, ... }: path: dotObject:
    if builtins.hasAttr "disabled" dotObject
    then { }
    else if builtins.hasAttr "config" dotObject
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

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkSystemModule = mkSystemModule: dotModule: { pkgs, ... } @specialArgs:
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

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkHomeModule = mkHomeModule: dotModule: { pkgs, ... } @specialArgs:
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
in
{
  mkSystemModule = mkSystemModule mkSystemModule;
  mkHomeModule = mkHomeModule mkHomeModule;
}
