{
  machines.nixosModules.commands =
    {
      lib,
      ...
    }:
    {
      options.dot = {
        commands = {
          pinentry = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default pinentry package.

              The package's main program should be an assuan protocol server
              (https://www.gnupg.org/documentation/manuals/assuan/Assuan.html).
            '';
          };

          mangohud = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default mangohud package.

              The package should just contain mangohud
              or a compatible binary.
            '';
          };

          gamemode = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default gamemode package.

              The package should just contain gamemode
              or a compatible binary.
            '';
          };

          gamescope = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default gamescope package.

              The package should just contain gamescope
              or a compatible binary.
            '';
          };
        };
      };
    };

  machines.homeModules.commands =
    { lib, ... }:
    {
      options.dot = {
        commands = {
          copy = lib.mkOption {
            type = lib.types.package;
            description = ''
              Copy command.

              The package's main program should take input from stdin
              and put it in the clipboard.
              On top of this, it should also allow for a "-t" option
              to override the MIME type of the stdin content
              and a "-l" option to list MIME types in the clipboard.
            '';
          };

          paste = lib.mkOption {
            type = lib.types.package;
            description = ''
              Paste command.

              The package's main program should print clipboard content on stdout.
              On top of this, it should also allow for a "-t" option
              to override the MIME type of the stdout content
              and a "-l" option to list MIME types in the clipboard.
            '';
          };

          type = lib.mkOption {
            type = lib.types.package;
            description = ''
              Type command.

              The package's main program should take text from stdin and
              generate keystrokes.
            '';
          };

          screenshot = lib.mkOption {
            type = lib.types.package;
            description = ''
              Screenshot command.

              The package's main program should take a screenshot,
              save it in "config.dot.desktop.screenshots"
              with the "config.dot.desktop.timestamp" formatted timestamp
              and "png" extension, notify the user via libnotify,
              and copy the screenshot to clipboard.
            '';
          };

          regionshot = lib.mkOption {
            type = lib.types.package;
            description = ''
              Region screenshot command.

              The package's main program should ask the user to select a screen region,
              take a screenshot of the selected region,
              save it in "config.dot.desktop.screenshots"
              with the "config.dot.desktop.timestamp" formatted timestamp
              and "png" extension, notify the user via libnotify,
              and copy the screenshot to clipboard.
            '';
          };

          tree = lib.mkOption {
            type = lib.types.package;
            description = ''
              Directory tree command.

              The package's main program should print the directory structure
              of the working directory recursively in a tree-like format
              to stdout ignoring gitignore-d files.
            '';
          };

          list = lib.mkOption {
            type = lib.types.package;
            description = ''
              Directory list command.

              The package's main program should print the directory structure
              of the working directory in a list-like format
              to stdout ignoring gitignore-d files.
            '';
          };

          dmenu = lib.mkOption {
            type = lib.types.package;
            description = ''
              Dmenu command.

              The package's main program should emulate dmenu behavior
              (https://tools.suckless.org/dmenu/). It should take strings
              from stdin delimited by newline characters,
              display a graphical menu where the strings from stdin are choices
              and print the user selected string on stdout.
            '';
          };

          launcher = lib.mkOption {
            type = lib.types.package;
            description = ''
              Program picker command.

              The package's main program should display a graphical menu
              of all the runnable desktop entries to the user and run
              the user selected one.
            '';
          };

          emoji = lib.mkOption {
            type = lib.types.package;
            description = ''
              Emoji picker command.

              The package's main program should display a graphical menu
              of all emojis and copy the user selected emoji to the clipboard.
            '';
          };

          volume-up = lib.mkOption {
            type = lib.types.package;
            description = ''
              Volume increase command.

              The package's main program should slightly increase
              the default output audio interface's volume.
            '';
          };

          volume-down = lib.mkOption {
            type = lib.types.package;
            description = ''
              Volume decrease command.

              The package's main program should slightly decrease
              the default output audio interface's volume.
            '';
          };

          volume-mute-unmute = lib.mkOption {
            type = lib.types.package;
            description = ''
              Mute/unmute command.

              The package's main program should toggle mute/unmute on
              the default output audio interface.
            '';
          };

          play-pause = lib.mkOption {
            type = lib.types.package;
            description = ''
              Play/pause command.

              The package's main program should toggle play/pause on
              the currently running media player on the system.
            '';
          };

          brightness-up = lib.mkOption {
            type = lib.types.package;
            description = ''
              Brightness increase command.

              The package's main program should slightly increase
              brightness on the main monitor.
            '';
          };

          brightness-down = lib.mkOption {
            type = lib.types.package;
            description = ''
              Brightness decrease command.

              The package's main program should slightly decrease
              brightness on the main monitor.
            '';
          };
        };
      };
    };
}
