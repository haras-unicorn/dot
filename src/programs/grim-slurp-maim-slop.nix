{
  pkgs,
  lib,
  config,
  ...
}:

let
  mkScreenshot =
    {
      name,
      command,
      runtimeInputs,
      ...
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        config.dot.shell.copy
        pkgs.coreutils
        pkgs.libnotify
      ]
      ++ runtimeInputs;
      text = ''
        tmp="$(mktemp -d)"
        mkdir -p "$tmp"
        trap 'rm -rf "$tmp"' EXIT

        type="png"
        name="$(date -Iseconds)"
        ${command}
        copy -t image/$type < "$tmp/$name.$type"
        notify-send --icon="$tmp/$name.$type" Clipboard "copied '$name.$type'" --transient

        dir="${config.xdg.userDirs.pictures}/screenshots"
        mkdir -p "$dir"
        mv "$tmp/$name.$type" "$dir/$name.$type"
      '';
    };

  screenshotWayland = mkScreenshot {
    name = "screenshot";
    runtimeInputs = [ pkgs.grim ];
    command = ''grim -t "$type" "$tmp/$name.$type"'';
  };

  screenshotXServer = mkScreenshot {
    name = "screenshot";
    runtimeInputs = [ pkgs.maim ];
    command = ''maim -u "$tmp/$name.$type"'';
  };

  regionshotWayland = mkScreenshot {
    name = "regionshot";
    runtimeInputs = [
      pkgs.grim
      pkgs.slurp
    ];
    command = ''grim -g "$(slurp)" -t "$type" "$tmp/$name.$type"'';
  };

  regionshotXServer = mkScreenshot {
    name = "regionshot";
    runtimeInputs = [
      pkgs.maim
      pkgs.slop
    ];
    command = ''maim -u -g "$(slop -f "%wx%h+%x+%y")" "$tmp/$name.$type"'';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  homeManagerModule = lib.mkMerge [
    (lib.mkIf (hasMonitor && hasWayland) {
      dot.shell.screenshot = screenshotWayland;
      dot.shell.regionshot = regionshotWayland;
      home.packages = [
        pkgs.grim
        pkgs.slurp
      ];
    })
    (lib.mkIf (hasMonitor && !hasWayland) {
      dot.shell.screenshot = screenshotXServer;
      dot.shell.regionshot = regionshotXServer;
      home.packages = [
        pkgs.maim
        pkgs.slop
      ];
    })
  ];
}
