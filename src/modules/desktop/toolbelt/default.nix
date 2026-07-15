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

      packages = builtins.concatLists [
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.sources))
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.nodes))
        (builtins.map ({ package, ... }: package) (builtins.attrValues config.dot.processing.sinks))
      ];

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

      inputs =
        (
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
        )
        ++ [
          pkgs.file
          pkgs.python3
        ];

      path = builtins.concatStringsSep " " (map (package: ''"${lib.getBin package}/bin"'') inputs);

      dmenu = lib.getExe config.dot.commands.dmenu;

      ui =
        if hardware.graphics then
          builtins.readFile ./gui.nu
        else if hardware.editor then
          builtins.readFile ./tui.nu
        else
          "";

      common = ''
        $env.DOT_TOOLBELT_TOOLS = r#'${tools}'#r | from json
        $env.DOT_TOOLBELT_DMENU = "${dmenu}"
        $env.PATH ++= [ ${path} ]

        ${builtins.readFile ./log.nu}

        ${builtins.readFile ./common.nu}

        def "main tools" []: nothing -> record {
          $env.DOT_TOOLBELT_TOOLS
        }
      '';

      toolbelt = pkgs.writeScriptBin "toolbelt" ''
        #!${lib.getExe pkgs.nushell} --stdin

        $env.DOT_TOOLBELT_SCRIPT = "toolbelt"

        ${common}

        ${ui}

        def "main" [] {
        ${builtins.readFile ./toolbelt.nu}
        }
      '';

      pipeline = pkgs.writeScriptBin "pipeline" ''
        #!${lib.getExe pkgs.nushell} --stdin

        $env.DOT_TOOLBELT_SCRIPT = "pipeline"

        ${common}

        ${ui}

        def "main" [] {
        ${builtins.readFile ./pipeline.nu}
        }
      '';
    in
    lib.mkIf (hardware.editor || hardware.graphics) {
      home.packages = [
        toolbelt
        pipeline
      ]
      ++ packages;

      dot.desktop.keybinds = [
        {
          mods = [
            "super"
          ];
          key = "s";
          command = lib.getExe pipeline;
        }
        {
          mods = [
            "super"
            "ctrl"
          ];
          key = "s";
          command = lib.getExe toolbelt;
        }
      ];
    };
}
