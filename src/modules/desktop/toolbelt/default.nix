# TODO: static list of pipelines with unique names and icons to execute in streams and add to picker
# TODO: fuzzy find for picker
# TODO: video caputure source
# TODO: image editing node with pinta - continue on exit
# TODO: video editing node with kdenlive - continue on exit
# TODO: audio editing node with audacity - continue on exit
# TODO: text editing nodes with helix/zed - continue on exit
# TODO: actual audio streaming with pcm cuz wav is finicky
# TODO: conversion nodes for wav to pcm and reverse
# TODO: image generation node
# TODO: text generation node

# LATER:
# TODO: make a rust app out of this and auto check each config by pulling through generated files
# TODO: find desktop entry files of sinks and parse them
# TODO: make emoji picker from dmenu command and unicode-emoji package
# TODO: add exec param to mime apps so it can be overriden if necessary
# TODO: stdin/stdout sink/source in the toolbelt module
# TODO: peek command thats like a modifier for sinking that doesnt remove contents
# TODO: alternative picker for pipelines like a mouse menu (kando package)
# TODO: audio generation node
# TODO: audio description node
# TODO: video generation node
# TODO: video description node
# TODO: video audio extraction node
{
  machines.homeModules.toolbelt =
    {
      pkgs,
      lib,
      osConfig,
      config,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      tools = builtins.toJSON {
        sources = builtins.mapAttrs (_: source: {
          inherit (source)
            display
            tags
            note
            output
            ;
          exe = lib.getExe source.package;
        }) config.dot.processing.sources;
        nodes = builtins.mapAttrs (_: node: {
          inherit (node)
            display
            tags
            note
            inputs
            output
            ;
          exe = lib.getExe node.package;
        }) config.dot.processing.nodes;
        sinks = builtins.mapAttrs (_: sink: {
          inherit (sink)
            display
            tags
            note
            inputs
            ;
          exe = lib.getExe sink.package;
        }) config.dot.processing.sinks;
      };

      installPackages = builtins.concatLists [
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.sources))
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.nodes))
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.sinks))
      ];

      toolbeltPackages = [
        pkgs.file
        pkgs.python3
      ]
      ++ (
        if hardware.graphics then
          [
            pkgs.zenity
          ]
        else if hardware.editor then
          [
            pkgs.gum
          ]
        else
          [ ]
      );

      path = builtins.concatStringsSep " " (
        map (package: ''"${lib.getBin package}/bin"'') toolbeltPackages
      );

      ui =
        if hardware.graphics then
          builtins.readFile ./gui.nu
        else if hardware.editor then
          builtins.readFile ./tui.nu
        else
          "";

      render = builtins.replaceStrings [ "DOT_TOOLBELT_TOOLS" ] [ tools ] (builtins.readFile ./main.nu);

      package = pkgs.writeScriptBin "toolbelt" ''
        #!${lib.getExe pkgs.nushell}

        $env.PATH ++= [ ${path} ]

        def "main" [] {
        ${ui}
        ${render}
        }
      '';
    in
    lib.mkIf (hardware.editor || hardware.graphics) {
      home.packages = [ package ] ++ installPackages;

      dot.desktop.keybinds = [
        {
          mods = [ "super" ];
          key = "s";
          command = lib.getExe package;
        }
      ];
    };
}
