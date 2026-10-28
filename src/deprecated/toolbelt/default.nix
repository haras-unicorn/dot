# TODO: static list of pipelines with unique names and icons to execute in streams and add to picker

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

# NOTE: the toolbelt and everything that fed `dot.processing` (sources, nodes,
# sinks and pipelines) lives here now. Import
# `self.lib.deprecated.homeModules.toolbelt` to bring all of it back: it brings
# the options, the toolbelt scripts, the pipelines and the per-program
# integrations below. The integrations used to live in the program modules and
# they still expect the options those modules define (e.g. `dot.commands`,
# `dot.pinentry`, `dot.piper`, `dot.espeak`, `dot.sound`, `dot.mime`).
# The blocks at the bottom came from other deprecated modules and are only kept
# as reference.
{ selfLib, ... }:

let
  processing = {
    sources = {
      speech-to-text = "speech-to-text";
      screenshot = "screenshot";
      regionshot = "regionshot";
    };
    nodes = {
      speech-to-text = "speech-to-text";
    };
    sinks = {
      type = "type";
      image-edit = "image-edit";
    };
  };

  toolbeltMime = {
    audio = "audio/x-raw";
  };

  mime = selfLib.mime.default;

  audioFormat = builtins.replaceStrings [ "audio/" ] [ "" ] mime.audio;
  videoFormat =
    let
      format = builtins.replaceStrings [ "video/" ] [ "" ] mime.video;
    in
    if format == "mkv" then "matroska" else format;
  imageFormat = builtins.replaceStrings [ "image/" ] [ "" ] mime.image;
  textFormat = builtins.replaceStrings [ "text/" ] [ "" ] mime.text;

  ffmpegOverlay = final: _prev: {
    ffmpeg-audio = final.writeShellApplication {
      name = "ffmpeg-audio";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        if echo "$DOT_TOOLBELT_MIME" | grep -q "^${toolbeltMime.audio}"; then
          rate=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*rate=\([[:digit:]]*\).*/\1/p')
          channels=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*channels=\([[:digit:]]*\).*/\1/p')
          fmt=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*format=\([0-9a-zA-Z\-_]*\).*/\1/p')
          rate=''${rate:-48000}
          channels=''${channels:-2}
          case "$fmt" in
            s16) fmt="s16le" ;;
            s24) fmt="s24le" ;;
            s32) fmt="s32le" ;;
            f32) fmt="f32le" ;;
            *)   fmt=''${fmt:-s16le} ;;
          esac
          ffmpeg -f "$fmt" -ar "$rate" -ac "$channels" -i pipe:0 -f ${audioFormat} pipe:1
        else
          ffmpeg -i pipe:0 -f ${audioFormat} pipe:1
        fi
      '';
    };

    ffmpeg-video = final.writeShellApplication {
      name = "ffmpeg-video";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        ffmpeg -i pipe:0 -f ${videoFormat} pipe:1
      '';
    };

    ffmpeg-image = final.writeShellApplication {
      name = "ffmpeg-image";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        ffmpeg -i pipe:0 -f image2pipe -vcodec ${imageFormat} pipe:1
      '';
    };

    ffmpeg-pcm = final.writeShellApplication {
      name = "ffmpeg-pcm";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        ffmpeg -i pipe:0 -f s16le -ar 48000 -ac 2 pipe:1
      '';
    };
  };

  optionsModule =
    { lib, ... }:
    let
      common =
        { name, ... }:
        {
          options = {
            display = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Display name";
            };
            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Search tags";
            };
            note = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Additional explanatory note";
            };
          };
        };

      processor =
        { name, ... }:
        {
          imports = [ common ];

          options = {
            aliases = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Processor aliases";
            };
            package = lib.mkOption {
              type = lib.types.package;
              description = "Processor package";
            };
            form = lib.mkOption {
              type = lib.types.nullOr lib.types.deferredModule;
              default = null;
              description = "Optional processor options";
            };
          };
        };
    in
    {
      options.dot = {
        processing = {
          sources = lib.mkOption {
            description = "Processing sources";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ processor ];

                options = {
                  output = lib.mkOption {
                    type = lib.types.oneOf [
                      lib.types.str
                      (lib.types.enum [ "detect" ])
                    ];
                    description = "Source output MIME type";
                  };
                };
              }
            );
          };

          nodes = lib.mkOption {
            description = "Processing nodes";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ processor ];

                options = {
                  inputs = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      (lib.types.enum [ "any" ])
                    ];
                    description = "Node input MIME types";
                  };
                  output = lib.mkOption {
                    type = lib.types.oneOf [
                      lib.types.str
                      (lib.types.enum [ "detect" ])
                    ];
                    description = "Node output MIME type";
                  };
                };
              }
            );
          };

          sinks = lib.mkOption {
            description = "Processing sinks";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ processor ];

                options = {
                  inputs = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      (lib.types.enum [ "any" ])
                    ];
                    description = "Sink input MIME types";
                  };
                };
              }
            );
          };

          pipelines = lib.mkOption {
            description = "Processing pipelines";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ common ];

                options = {
                  source = lib.mkOption {
                    type = lib.types.str;
                    description = "Source name or alias for this pipeline";
                  };

                  nodes = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "List of nodes names or aliases for this pipeline";
                  };

                  sink = lib.mkOption {
                    type = lib.types.str;
                    description = "Sink for this pipeline";
                  };
                };
              }
            );
          };
        };
      };
    };

  toolbeltModule =
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
          pkgs.nushell
        ];

      path = builtins.concatStringsSep " " (map (package: ''"${lib.getBin package}/bin"'') inputs);

      dmenu = lib.getExe config.dot.commands.dmenu;

      kando = lib.getExe config.dot.commands.kando;

      ui =
        if hardware.graphics then
          builtins.readFile ./gui.nu
        else if hardware.editor then
          builtins.readFile ./tui.nu
        else
          "";

      common = ''
        $env.DOT_TOOLBELT_TOOLS = r#'${tools}'# | from json
        $env.DOT_TOOLBELT_DMENU = "${dmenu}"
        $env.DOT_TOOLBELT_KANDO = "${kando}"
        $env.PATH ++= [ ${path} ]

        ${builtins.readFile ./log.nu}

        ${builtins.readFile ./common.nu}

        def "main tools" []: nothing -> string {
          $env.DOT_TOOLBELT_TOOLS | to json
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
    lib.mkIf
      (
        (hardware.editor || hardware.graphics)
        && config.dot.commands.dmenu != null
        && config.dot.commands.kando != null
      )
      {
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
            key = "q";
            command = lib.getExe pipeline;
          }
          {
            mods = [
              "super"
              "ctrl"
            ];
            key = "q";
            command = lib.getExe toolbelt;
          }
        ];
      };

  pipelinesModule =
    { osConfig, lib, ... }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.editor || hardware.graphics) {
      dot.processing.pipelines = {
        screenshot-edit = {
          note = "Edit screenshot";
          tags = [
            "screenshot"
            "image"
            "edit"
          ];
          source = processing.sources.screenshot;
          sink = processing.sinks.image-edit;
        };
        type-speech = {
          note = "Type speech";
          tags = [
            "text"
            "speech"
            "type"
          ];
          source = processing.sources.speech-to-text;
          sink = processing.sinks.type;
        };
      };
    };

  integrations = {
    pinentry-wayprompt =
      {
        osConfig,
        pkgs,
        lib,
        ...
      }:
      let
        processor = pkgs.writeShellApplication {
          name = "pinentry-processor";
          text = ''
            echo GETPIN \
              | ${lib.getExe osConfig.dot.pinentry.package} \
              | grep '^D ' \
              | cut -c3-
          '';
        };
      in
      {
        dot.processing.sources.pinentry = {
          note = "Capture a secure string (e.g. password or pin or key)";
          tags = [
            "password"
            "pin"
            "key"
            "secure"
            "string"
            "text"
          ];
          output = "text/plain";
          package = processor;
        };
      };

    losslesscut =
      {
        osConfig,
        lib,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = pkgs.losslesscut;

        sink = pkgs.writeShellApplication {
          name = "losslesscut-sink-edit";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            cat > "$tmp"
            losslesscut "$tmp" &>/dev/null
          '';
        };
      in
      lib.mkIf hardware.browser {
        dot.processing.sinks.losslesscut-edit = {
          note = "Edit video or audio";
          tags = [
            "editor"
            "video"
            "audio"
          ];
          inputs = selfLib.mime.video ++ selfLib.mime.audio;
          package = sink;
        };
      };

    zenity =
      {
        lib,
        osConfig,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = pkgs.zenity;
      in
      lib.mkIf hardware.graphics {
        dot.processing = {
          sources = {
            zenity = {
              note = "Pick a file";
              tags = [
                "file"
                "picker"
                "load"
                "read"
              ];
              output = "detect";
              package = pkgs.writeShellApplication {
                name = "zenity-file-source";
                runtimeInputs = [ package ];
                text = ''
                  cat < "$(zenity --file-selection)"
                '';
              };
            };
          };
          sinks = {
            zenity = {
              note = "Save to file";
              tags = [
                "file"
                "picker"
                "save"
                "write"
              ];
              inputs = "any";
              package = pkgs.writeShellApplication {
                name = "zenity-file-sink";
                runtimeInputs = [ package ];
                text = ''
                  cat > "$(zenity --file-selection --save)"
                '';
              };
            };
          };
        };
      };

    tenacity =
      {
        osConfig,
        lib,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = pkgs.tenacity;

        sink = pkgs.writeShellApplication {
          name = "tenacity-sink-edit";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            cat > "$tmp"
            tenacity "$tmp" &>/dev/null
          '';
        };
      in
      lib.mkIf hardware.browser {
        dot.processing.sinks.tenacity-edit = {
          note = "Edit audio";
          tags = [ "audio" ];
          inputs = selfLib.mime.video ++ selfLib.mime.audio;
          package = sink;
        };
      };

    hyprpicker =
      { pkgs, ... }:
      let
        source = pkgs.writeShellApplication {
          name = "hyprpicker-source";
          runtimeInputs = [ pkgs.hyprpicker ];
          text = "hyprpicker --no-fancy";
        };
      in
      {
        dot.processing.sources.hyprpicker = {
          note = "Pick a single pixel on the screen and save its hex value";
          tags = [
            "color"
            "picker"
            "hex"
            "screen"
          ];
          output = "text/plain";
          package = source;
        };
      };

    zed =
      {
        osConfig,
        config,
        pkgs,
        lib,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = config.programs.zed-editor.package;

        source = pkgs.writeShellApplication {
          name = "zed-editor-source";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            zeditor --foreground -n "$tmp" &>/dev/null
            cat "$tmp"
          '';
        };

        node = pkgs.writeShellApplication {
          name = "zed-editor-node";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            cat > "$tmp"
            zeditor --foreground -n "$tmp" &>/dev/null
          '';
        };
      in
      lib.mkIf hardware.visual {
        dot.processing = {
          sources.zed-editor = {
            note = "Write text";
            tags = [
              "text"
              "write"
            ];
            output = "detect";
            package = source;
          };
          nodes.zed-editor = {
            note = "Edit text";
            tags = [
              "text"
              "editor"
            ];
            inputs = selfLib.mime.editor;
            output = "detect";
            package = node;
          };
        };
      };

    helix =
      {
        osConfig,
        config,
        lib,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = config.programs.helix.package;

        terminal = lib.getExe config.dot.programs.terminal.package;

        nodeCommand = if hardware.graphics then ''${terminal} hx "$tmp"'' else ''hx "$tmp"'';

        source = pkgs.writeShellApplication {
          name = "helix-editor-source";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            ${nodeCommand} &>/dev/null
            cat "$tmp"
          '';
        };

        node = pkgs.writeShellApplication {
          name = "helix-editor-node";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            cat > "$tmp"
            ${nodeCommand} &>/dev/null
          '';
        };
      in
      lib.mkIf hardware.editor {
        dot.processing = {
          sources.helix-editor = {
            note = "Write text";
            tags = [
              "text"
              "write"
            ];
            output = "text/plain";
            package = source;
          };

          nodes.helix-editor = {
            note = "Edit text";
            tags = [
              "text"
              "editor"
            ];
            inputs = selfLib.mime.editor;
            output = "detect";
            package = node;
          };
        };
      };

    wf-recorder-slurp =
      {
        osConfig,
        lib,
        pkgs,
        ...
      }:
      let
        cuda = osConfig.dot.hardware.cuda;

        codec = if cuda then "hevc_nvenc" else "libx265";

        hardware = osConfig.dot.hardware;

        wf-recorder = pkgs.wf-recorder;

        slurp = pkgs.slurp;

        screenrecordSource = pkgs.writeShellApplication {
          name = "wf-recorder-source";
          runtimeInputs = [
            wf-recorder
          ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            wf-recorder -c ${codec} -o "$tmp" &>/dev/null
            cat "$tmp"
          '';
        };

        regionrecordSource = pkgs.writeShellApplication {
          name = "wf-recorder-slurp-source";
          runtimeInputs = [
            wf-recorder
            slurp
          ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            wf-recorder -g "$(slurp)" -c ${codec} -o "$tmp" &>/dev/null
            cat "$tmp"
          '';
        };
      in
      lib.mkIf (hardware.browser && hardware.wayland) {
        dot.processing.sources = lib.mkMerge [
          {
            wf-recorder = {
              note = "Take a screen recording";
              tags = [
                "image"
                "record"
                "screen"
              ];
              output = "image/png";
              package = screenrecordSource;
            };
          }
          (lib.mkIf hardware.pointing {
            wf-recorder-slurp = {
              note = "Take a screen recording of a screen region";
              tags = [
                "image"
                "record"
                "screen"
                "region"
              ];
              output = "image/png";
              package = regionrecordSource;
            };
          })
        ];
      };

    wl-clipboard-xclip =
      {
        pkgs,
        lib,
        osConfig,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;
      in
      lib.mkMerge [
        (lib.mkIf (hardware.graphics && hardware.wayland) {
          dot.processing = {
            sources = {
              wl-clipboard = {
                note = "Paste contents of the clipboard";
                tags = [
                  "clipboard"
                  "paste"
                ];
                output = "detect";
                package = pkgs.harasPackages.paste-wl;
              };
            };
            sinks = {
              wl-clipboard = {
                note = "Copy contents to the clipboard";
                tags = [
                  "clipboard"
                  "copy"
                ];
                inputs = "any";
                package = pkgs.harasPackages.copy-wl;
              };
            };
          };
        })
        (lib.mkIf (hardware.graphics && !hardware.wayland) {
          dot.processing = {
            sources = {
              xclip = {
                note = "Paste contents of the clipboard";
                tags = [
                  "clipboard"
                  "paste"
                ];
                output = "detect";
                package = pkgs.harasPackages.paste-x;
              };
            };
            sinks = {
              xclip = {
                note = "Copy contents to the clipboard";
                tags = [
                  "clipboard"
                  "copy"
                ];
                inputs = "any";
                package = pkgs.harasPackages.copy-x;
              };
            };
          };
        })
      ];

    grim-slurp-maim-slop =
      {
        pkgs,
        lib,
        osConfig,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        grimSource = pkgs.writeShellApplication {
          name = "grim-source";
          runtimeInputs = [ pkgs.grim ];
          text = ''grim -t "png" -'';
        };

        maimSource = pkgs.writeShellApplication {
          name = "maim-source";
          runtimeInputs = [ pkgs.maim ];
          text = ''maim -u -f "png"'';
        };

        grimSlurpSource = pkgs.writeShellApplication {
          name = "grim-slurp-source";
          runtimeInputs = [
            pkgs.grim
            pkgs.slurp
          ];
          text = ''grim -g "$(slurp)" -t "png" -'';
        };

        maimSlopSource = pkgs.writeShellApplication {
          name = "maim-slop-source";
          runtimeInputs = [
            pkgs.maim
            pkgs.slop
          ];
          text = ''maim -u -g "$(slop -f "%wx%h+%x+%y")" -f "png"'';
        };
      in
      lib.mkMerge [
        (lib.mkIf (hardware.graphics && hardware.wayland) {
          dot.processing.sources = lib.mkMerge [
            {
              grim = {
                note = "Take a screenshot";
                tags = [
                  "image"
                  "screenshot"
                  "screen"
                ];
                output = "image/png";
                aliases = [ processing.sources.screenshot ];
                package = grimSource;
              };
            }
            (lib.mkIf hardware.pointing {
              grim-slurp = {
                note = "Take a screenshot of a screen region";
                tags = [
                  "image"
                  "screenshot"
                  "screen"
                  "region"
                ];
                output = "image/png";
                aliases = [ processing.sources.regionshot ];
                package = grimSlurpSource;
              };
            })
          ];
        })
        (lib.mkIf (hardware.graphics && !hardware.wayland) {
          dot.processing.sources = lib.mkMerge [
            {
              maim = {
                note = "Take a screenshot";
                tags = [
                  "image"
                  "screenshot"
                  "screen"
                ];
                aliases = [ processing.sources.screenshot ];
                output = "image/png";
                package = maimSource;
              };
            }
            (lib.mkIf hardware.pointing {
              maim-slop = {
                note = "Take a screenshot of a screen region";
                tags = [
                  "image"
                  "screenshot"
                  "screen"
                  "region"
                ];
                aliases = [ processing.sources.regionshot ];
                output = "image/png";
                package = maimSlopSource;
              };
            })
          ];
        })
      ];

    ffmpeg =
      { pkgs, ... }:
      let
        ffmpegPackages = ffmpegOverlay pkgs pkgs;

        text = pkgs.writeShellApplication {
          name = "ffmpeg-text";
          runtimeInputs = [ ];
          text = ''
            cat
          '';
        };
      in
      {
        dot.processing.nodes = {
          ffmpeg-audio = {
            note = "Convert any audio format to ${audioFormat}";
            tags = [
              "convert"
              "audio"
              audioFormat
              "format"
              "ffmpeg"
            ];
            aliases = [ "audio-${videoFormat}" ];
            inputs = selfLib.mime.audio ++ [ toolbeltMime.audio ];
            output = mime.audio;
            package = ffmpegPackages.ffmpeg-audio;
          };

          ffmpeg-video = {
            note = "Convert any video format to ${videoFormat}";
            tags = [
              "convert"
              "video"
              "${videoFormat}"
              "format"
              "ffmpeg"
            ];
            aliases = [ "video-${videoFormat}" ];
            inputs = selfLib.mime.video;
            output = mime.video;
            package = ffmpegPackages.ffmpeg-video;
          };

          ffmpeg-image = {
            note = "Convert any image format to ${imageFormat}";
            tags = [
              "convert"
              "image"
              "${imageFormat}"
              "format"
              "ffmpeg"
            ];
            aliases = [ "image-${imageFormat}" ];
            inputs = selfLib.mime.image;
            output = mime.image;
            package = ffmpegPackages.ffmpeg-image;
          };

          "text-${textFormat}" = {
            note = "Ensure text data is ${textFormat}";
            tags = [
              "convert"
              "text"
              "${textFormat}"
              "passthrough"
              "id"
              "format"
            ];
            aliases = [
              "passthrough"
              "id"
            ];
            inputs = selfLib.mime.editor;
            output = mime.text;
            package = text;
          };

          ffmpeg-pcm = {
            note = "Convert any audio format to raw PCM";
            tags = [
              "convert"
              "audio"
              "pcm"
              "raw"
              "ffmpeg"
            ];
            aliases = [ "audio-pcm" ];
            inputs = selfLib.mime.audio;
            output = "${toolbeltMime.audio}; rate=48000; channels=2; format=s16";
            package = ffmpegPackages.ffmpeg-pcm;
          };
        };
      };

    pinta =
      {
        osConfig,
        lib,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = pkgs.pinta;

        sink = pkgs.writeShellApplication {
          name = "pinta-sink-edit";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            cat > "$tmp"
            pinta "$tmp"
          '';
        };
      in
      lib.mkIf hardware.browser {
        dot.processing.sinks.pinta-edit = {
          note = "Edit an image";
          tags = [
            "editor"
            "image"
          ];
          aliases = [ processing.sinks.image-edit ];
          inputs = selfLib.mime.image;
          package = sink;
        };
      };

    footage =
      {
        osConfig,
        lib,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = pkgs.symlinkJoin {
          name = "footage";
          paths = [ pkgs.footage ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/footage \
              --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}"
          '';
        };

        sink = pkgs.writeShellApplication {
          name = "footage-sink-edit";
          runtimeInputs = [ package ];
          text = ''
            tmp="$(mktemp -p /tmp "XXXXXXXX.$DOT_TOOLBELT_EXTENSION")"
            trap 'rm -f "$tmp"' EXIT
            cat > "$tmp"
            footage "$tmp" &>/dev/null
          '';
        };
      in
      lib.mkIf hardware.browser {
        dot.processing.sinks.footage-edit = {
          note = "Edit video or audio";
          tags = [
            "editor"
            "video"
            "audio"
          ];
          inputs = selfLib.mime.video ++ selfLib.mime.audio;
          package = sink;
        };
      };

    gum =
      {
        lib,
        osConfig,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = pkgs.gum;
      in
      lib.mkIf hardware.editor {
        dot.processing = lib.mkIf (!hardware.graphics) {
          sources = {
            gum = {
              note = "Pick a file";
              tags = [
                "file"
                "picker"
                "load"
                "read"
              ];
              output = "detect";
              package = pkgs.writeShellApplication {
                name = "gum-file-source";
                runtimeInputs = [ package ];
                text = ''
                  cat < "$(gum file)"
                '';
              };
            };
          };
          sinks = {
            gum = {
              note = "Save to file";
              tags = [
                "file"
                "picker"
                "save"
                "write"
              ];
              inputs = "any";
              package = pkgs.writeShellApplication {
                name = "gum-file-sink";
                runtimeInputs = [ package ];
                text = ''
                  cat > "$(gum input)"
                '';
              };
            };
          };
        };
      };

    whisper-cpp =
      {
        pkgs,
        lib,
        osConfig,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        cuda = hardware.cuda;

        models = {
          tinyVad = pkgs.fetchurl {
            url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin";
            hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
          };

          tinyModel = pkgs.fetchurl {
            url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin";
            hash = "sha256-kh5M+Ghv3Zk9zQgaXaW2w2W/3hFi5ysI11rHUomSCx8=";
          };
        };

        # NOTE: like this because some libs
        # otherwise conflict with other packages
        package = pkgs.buildEnv {
          name = "whisper-cpp";
          paths = [ pkgs.whisper-cpp ];
          pathsToLink = [ "/bin" ];
        };

        transcribeNode = pkgs.writeShellApplication {
          name = "whisper-cpp-node-transcribe";
          runtimeInputs = [
            package
          ];
          text = ''
            tmpin="$(mktemp --suffix ".$DOT_TOOLBELT_EXTENSION")"
            tmpout="$(mktemp --suffix .txt)"
            trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
            cat > "$tmpin"
            whisper-cli \
              --model ${models.tinyModel} \
              --flash-attn ${if cuda then "on" else "off"} \
              --no-gpu ${if cuda then "off" else "on"} \
              --vad \
              --vad-model "${models.tinyVad}" \
              --no-timestamps \
              --no-prints \
              --output-txt \
              --output-file "''${tmpout%.*}" \
              "$tmpin" \
              1>/dev/null
            cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
          '';
        };

        streamSource =
          let
            zenityCheck = ''
              zenity \
                --question \
                --title="Recording..." \
                --text="Pressing yes saves the recording and pressing no cancels it." \
            '';

            gumCheck = ''
              gum \
                confirm \
                "Recording..." \
                --affirmative="Stop" \
                --negative="Cancel" \
            '';
          in
          pkgs.writeShellApplication {
            name = "whisper-stream-source";
            runtimeInputs = [
              package
              (if hardware.graphics then pkgs.zenity else pkgs.gum)
            ];
            text = ''
              whisper-stream \
                --model ${models.tinyModel} \
                ${lib.optionalString cuda "--flash-attn"} \
                ${lib.optionalString (!cuda) "--no-gpu"} \
                --language en \
                2>/dev/null \
                | stdbuf -oL sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
                | stdbuf -oL sed '/^\[.*\]$/d' \
                | stdbuf -oL sed 's/^[[:space:]]*//g' \
                | stdbuf -oL sed 's/[[:space:]]*$//g' \
                | stdbuf -oL sed 's/\r//g' \
                | stdbuf -oL tr -s ' ' \
                &
              pid=$!
              trap 'kill -SIGTERM "$pid" 2>/dev/null || true' EXIT

              if ! ${if hardware.graphics then zenityCheck else gumCheck} 2>/dev/null; then
                exit 1
              fi
            '';
          };
      in
      {
        dot.processing.sources.whisper-stream = {
          note = "Real-time speech recognition streaming from microphone";
          tags = [
            "transcription"
            "transcribe"
            "speech"
            "text"
            "stt"
            "speech-to-text"
            "stream"
            "streaming"
          ];
          aliases = [ processing.sources.speech-to-text ];
          output = "text/plain";
          package = streamSource;
        };

        dot.processing.nodes.whisper-cpp = {
          note = "Transcribe speech into text";
          tags = [
            "transcription"
            "transcribe"
            "speech"
            "text"
            "stt"
            "speech-to-text"
          ];
          inputs = [
            "audio/wav"
            "audio/x-wav"
            "audio/mpeg"
            "audio/ogg"
            "audio/flac"
          ];
          aliases = [ processing.nodes.speech-to-text ];
          output = "text/plain";
          package = transcribeNode;
        };
      };

    piper =
      { lib, osConfig, ... }:
      let
        hardware = osConfig.dot.hardware;
      in
      lib.mkIf hardware.sound {
        dot.processing.nodes.piper-tts = {
          note = "Turn text into speech";
          tags = [
            "tts"
            "text-to-speech"
            "text"
            "speech"
          ];
          inputs = [ "text/plain" ];
          output = "audio/x-raw; rate=${toString osConfig.dot.piper.sampleRate}; channels=1; format=s16";
          package = osConfig.dot.piper.node;
        };
      };

    tesseract =
      { pkgs, ... }:
      let
        package = pkgs.tesseract;

        processor = pkgs.writeShellApplication {
          name = "tesseract-processor";
          runtimeInputs = [ package ];
          text = ''
            cat | tesseract --psm 1 --oem 1 stdin stdout "$@" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
          '';
        };
      in
      {
        dot.processing.nodes.tesseract-ocr = {
          note = "Recognize the characters in the image";
          tags = [
            "ocr"
            "image"
            "text"
          ];
          inputs = [ "image/png" ];
          output = "text/plain";
          package = processor;
        };
      };

    ydotool =
      {
        osConfig,
        lib,
        pkgs,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        type = pkgs.writeShellApplication {
          name = "type";
          runtimeInputs = [
            pkgs.ydotool
          ];
          text = ''
            ydotool type --file -
          '';
        };
      in
      lib.mkIf hardware.visual {
        dot.processing.sinks."ydotool type" = {
          note = "Type text from stdin via ydotool";
          aliases = [ processing.sinks.type ];
          inputs = [ "text/plain" ];
          package = type;
        };
      };

    speechd-espeak =
      { osConfig, lib, ... }:
      let
        hardware = osConfig.dot.hardware;
      in
      lib.mkIf hardware.sound {
        dot.processing.nodes.espeak = {
          note = "Turn text into speech";
          tags = [
            "tts"
            "text-to-speech"
            "text"
            "speech"
          ];
          inputs = [ "text/plain" ];
          output = "audio/x-wav";
          package = osConfig.dot.espeak.processor;
        };
      };

    sound =
      {
        pkgs,
        lib,
        osConfig,
        ...
      }:
      let
        hardware = osConfig.dot.hardware;

        package = osConfig.dot.sound.pipewire;
      in
      lib.mkIf hardware.sound {
        dot.processing = {
          sinks = {
            pipewire = {
              note = "Play audio on the default output audio interface.";
              tags = [
                "play"
                "audio"
                "interface"
                "speakers"
                "headphones"
              ];
              inputs = [
                "audio/wav"
                "audio/x-wav"
                toolbeltMime.audio
              ];
              package = pkgs.writeShellApplication {
                name = "pipewire-sink-play";
                runtimeInputs = [ package ];
                text = ''
                  if echo "$DOT_TOOLBELT_MIME" | grep -q "^${toolbeltMime.audio}"; then
                    rate=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*rate=\([[:digit:]]*\).*/\1/p')
                    channels=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*channels=\([[:digit:]]*\).*/\1/p')
                    format=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*format=\([a-zA-Z0-9\-_]*\).*/\1/p')
                    rate=''${rate:-48000}
                    channels=''${channels:-2}
                    format=''${format:-s16}
                    pw-play --format "$format" --rate "$rate" --channels "$channels" --format "$format" -
                  else
                    cat > pw-play -
                  fi
                '';
              };
            };
          };
          sources = {
            pipewire = {
              note = "Record audio on the default input audio interface or easyeffects source if present.";
              tags = [
                "record"
                "audio"
                "interface"
                "microphone"
              ];
              output = "audio/x-raw; rate=48000; channels=2; format=s16";
              package =
                let
                  easyeffectsSource = "easyeffects_source";

                  jqEasyeffectsSelector = ''
                    [.[]
                      | select(
                          .type == "PipeWire:Interface:Node"
                          and .info.props["node.name"]
                          == "${easyeffectsSource}"
                        )
                    ]
                    | length
                  '';

                  zenityCheck = ''
                    zenity \
                      --question \
                      --title="Recording..." \
                      --text="Pressing yes saves the recording and pressing no cancels it." \
                  '';

                  gumCheck = ''
                    gum \
                      confirm \
                      "Recording..." \
                      --affirmative="Stop" \
                      --negative="Cancel" \
                  '';
                in
                pkgs.writeShellApplication {
                  name = "pipewire-source-record";
                  runtimeInputs = [
                    package
                    (if hardware.graphics then pkgs.zenity else pkgs.gum)
                    pkgs.jq
                  ];
                  text = ''
                    if [ "$(pw-dump \
                      | jq -e ${lib.escapeShellArg jqEasyeffectsSelector})" \
                      -eq 1 ]; then
                      pw-cat \
                        --record \
                        --format s16 \
                        --rate 48000 \
                        --channels 2 \
                        --target ${lib.escapeShellArg easyeffectsSource} \
                        - \
                        2>/dev/null \
                        &
                    else
                      pw-cat \
                        --record \
                        --format s16 \
                        --rate 48000 \
                        --channels 2 \
                        - \
                        2>/dev/null \
                        &
                    fi
                    pid=$!

                    if ${if hardware.graphics then zenityCheck else gumCheck} 2>/dev/null; then
                      kill "$pid" 2>/dev/null || true
                      wait "$pid" 2>/dev/null || true
                    else
                      kill "$pid" 2>/dev/null || true
                      wait "$pid" 2>/dev/null || true
                      exit 1
                    fi
                  '';
                };
            };
          };
        };
      };

    xdg =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        dot.processing.sinks = builtins.listToAttrs (
          builtins.map (
            { package, types, ... }:
            let
              name = lib.getName package;
            in
            {
              inherit name;
              value = {
                note = "Open";
                inputs = types;
                package = pkgs.writeShellApplication {
                  name = "${name}-sink";
                  text = ''
                    tmp="$(mktemp)"
                    trap 'rm -f "$tmp"' EXIT
                    cat > "$tmp"
                    ${lib.getExe package} "$tmp"
                  '';
                };
              };
            }
          ) config.dot.mime.apps
        );
      };
  };
in
{
  self.lib.deprecated.overlays.toolbelt-ffmpeg = ffmpegOverlay;

  self.lib.deprecated.homeModules.toolbelt =
    { ... }:
    {
      imports = [
        optionsModule
        toolbeltModule
        pipelinesModule
      ]
      ++ builtins.attrValues integrations;
    };
}

# NOTE: nodes that other deprecated modules used to register. They reference
# bindings from the modules they came from (e.g. `node-generate`), so they are
# only kept as reference.
#
# stable-diffusion-cpp:
#
#   dot.processing.nodes.stable-diffusion-cpp-generate = {
#     note = "Generate an image";
#     tags = [
#       "image"
#       "generate"
#       "generation"
#       "text"
#     ];
#     inputs = [ "text/plain" ];
#     output = "image/png";
#     package = node-generate;
#   };
#
# mistral-rs:
#
#   dot.processing.nodes.mistral-rs-clone-speech = {
#     note = "Clone speech";
#     tags = [
#       "clone"
#       "speech"
#       "generate"
#       "generation"
#       "text"
#     ];
#     inputs = [ "text/plain" ];
#     output = "audio/wav";
#     package = node-describe;
#   };
#
# llama-cpp:
#
#   dot.processing.nodes = {
#     llama-cpp-describe-image = {
#       note = "Describe an image into text";
#       tags = [
#         "image"
#         "describe"
#         "text"
#       ];
#       inputs = [ "image/png" ];
#       output = "text/plain";
#       package = node-describe-image;
#     };
#     llama-cpp-describe-audio = {
#       note = "Describe an audio into text";
#       tags = [
#         "audio"
#         "describe"
#         "text"
#       ];
#       inputs = [ "audio/wav" ];
#       output = "text/plain";
#       package = node-describe-audio;
#     };
#     llama-cpp-describe-text = {
#       note = "Describe text into text";
#       tags = [
#         "describe"
#         "text"
#       ];
#       inputs = [ "text/plain" ];
#       output = "text/plain";
#       package = node-describe-text;
#     };
#     llama-cpp-generate-text = {
#       note = "Generate text from text";
#       tags = [
#         "generate"
#         "text"
#       ];
#       inputs = [ "text/plain" ];
#       output = "text/plain";
#       package = node-generate-text;
#     };
#   };
