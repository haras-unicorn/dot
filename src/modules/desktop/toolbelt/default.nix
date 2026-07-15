# TODO: static list of pipelines with unique names and icons to execute in streams and add to picker
# TODO: fuzzy find for picker
# TODO: actual audio streaming with pcm cuz wav is finicky
# TODO: conversion nodes for wav to pcm and reverse

# LATER:
# TODO: make a rust app out of this and auto check each config by pulling through generated files
# TODO: find desktop entry files of sinks and parse them
# TODO: make emoji picker from dmenu command and unicode-emoji package
# TODO: add exec param to mime apps so it can be overridden if necessary
# TODO: stdin/stdout sink/source in the toolbelt module
# TODO: peek command thats like a modifier for sinking that doesn't remove contents
# TODO: alternative picker for pipelines like a mouse menu (kando package)
# TODO: audio generation node
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

      toolPackages = builtins.concatLists [
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.sources))
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.nodes))
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.sinks))
      ];

      uiInputs =
        if hardware.graphics then
          [
            pkgs.zenity
          ]
        else if hardware.editor then
          [
            pkgs.gum
          ]
        else
          [ ];

      uiPath = builtins.concatStringsSep " " (map (package: ''"${lib.getBin package}/bin"'') uiInputs);

      uiRender =
        if hardware.graphics then
          builtins.readFile ./gui.nu
        else if hardware.editor then
          builtins.readFile ./tui.nu
        else
          "";

      uiPackage = pkgs.writeScriptBin "ui" ''
        #!${lib.getExe pkgs.nushell} --stdin

        $env.DOT_TOOLBELT_SCRIPT = "ui"
        $env.PATH ++= [ ${uiPath} ]

        def "main" [] {
        }

        ${uiRender}
      '';

      tools = builtins.toJSON {
        sources = builtins.mapAttrs (_: source: {
          inherit (source)
            display
            tags
            aliases
            note
            output
            ;
          exe = lib.getExe source.package;
        }) config.dot.processing.sources;
        nodes = builtins.mapAttrs (_: node: {
          inherit (node)
            display
            tags
            aliases
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
            aliases
            note
            inputs
            ;
          exe = lib.getExe sink.package;
        }) config.dot.processing.sinks;
        pipelines = builtins.mapAttrs (_: pipeline: {
          inherit (pipeline)
            display
            tags
            aliases
            note
            source
            nodes
            sink
            ;
        }) config.dot.processing.pipelines;
      };

      toolbeltInputs = [
        pkgs.file
        pkgs.python3
        uiPackage
      ];

      toolbeltPath = builtins.concatStringsSep " " (
        map (package: ''"${lib.getBin package}/bin"'') toolbeltInputs
      );

      toolbeltRender = builtins.replaceStrings [ "DOT_TOOLBELT_TOOLS" ] [ tools ] (
        builtins.readFile ./toolbelt.nu
      );

      toolbeltPackage = pkgs.writeScriptBin "toolbelt" ''
        #!${lib.getExe pkgs.nushell} --stdin

        $env.DOT_TOOLBELT_SCRIPT = "toolbelt"
        $env.PATH ++= [ ${toolbeltPath} ]

        def "main" [] {
        ${toolbeltRender}
        }
      '';

      pipelineRender = builtins.replaceStrings [ "DOT_TOOLBELT_TOOLS" ] [ tools ] (
        builtins.readFile ./pipeline.nu
      );

      pipelinePackage = pkgs.writeScriptBin "pipeline" ''
        #!${lib.getExe pkgs.nushell} --stdin

        $env.DOT_TOOLBELT_SCRIPT = "pipeline"
        $env.PATH ++= [ ${toolbeltPath} ]

        def "main" [] {
        ${pipelineRender}
        }
      '';
    in
    lib.mkIf (hardware.editor || hardware.graphics) {
      home.packages = [
        toolbeltPackage
        pipelinePackage
      ]
      ++ toolPackages;

      dot.desktop.keybinds = [
        {
          mods = [
            "super"
          ];
          key = "s";
          command = lib.getExe pipelinePackage;
        }
        {
          mods = [
            "super"
            "ctrl"
          ];
          key = "s";
          command = lib.getExe toolbeltPackage;
        }
      ];
    };
}
