{ config, self, pkgs, lib, ... }:

# FIXME: hardware acceleration

let
  args = [
    "--enable-features=WebRTCPipeWireCapturer"
    "--enable-features=UseOzonePlatform"
    "--ozone-platform-hint=auto"
    "--use-gl=egl"
  ];

  flags = builtins.concatStringsSep
    " "
    (builtins.map
      (x: "--append-flags ${x}")
      args);

  hasMonitor = config.dot.hardware.monitor.enable;

  package = self.lib.chromium.wrap pkgs pkgs.ungoogled-chromium "chromium";
in
{
  flake.lib.chromium.wrap = pkgs: package: bin: pkgs.symlinkJoin {
    name = bin;
    paths = [ package ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''wrapProgram $out/bin/${bin} ${flags}'';
  };

  flake.lib.chromium.args = builtins.concatStringsSep " " args;

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    programs.chromium.enable = true;
    programs.chromium.package = package;
    programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
      en_US
    ];
    # NOTE: keeping here just in case i need them again
    # programs.chromium.extensions = [
    #   # ublock origin
    #   { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
    #   # dark reader
    #   { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
    #   # vimium c
    #   { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; }
    #   # vimium c new tab
    #   { id = "cglpcedifkgalfdklahhcchnjepcckfn"; }
    # ];
  };
}
