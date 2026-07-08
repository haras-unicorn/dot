{
  machines.nixosModules.gstreamer =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      plugins = with pkgs.gst_all_1; [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-plugins-rs
        gst-libav
      ];

      variables = [
        "GST_PLUGIN_SYSTEM_PATH"
        "GST_PLUGIN_SYSTEM_PATH_1_0"
        "GST_PLUGIN_PATH"
        "GST_PLUGIN_PATH_1_0"
      ];

      path = pkgs.lib.makeSearchPath "lib/gstreamer-1.0" plugins;

      wrapPrefixPath = builtins.concatStringsSep " " (
        builtins.map (variable: ''--prefix ${variable} : "${path}"'') variables
      );
    in
    {
      dot.programs.gstreamer = {
        inherit plugins;
        wrap =
          package:
          if lib.isDerivation package then
            pkgs.symlinkJoin {
              name = lib.getName package;
              paths = [ package ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram $out/bin/${builtins.baseNameOf (lib.getExe package)} ${wrapPrefixPath}";
            }
          else
            # NOTE: super hacky but should work 99% of the time
            pkgs.symlinkJoin {
              name = builtins.baseNameOf package;
              paths = [ (builtins.dirOf (builtins.dirOf package)) ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram $out/bin/${builtins.baseNameOf package} ${wrapPrefixPath}";
            };
      };

      home-manager.users.${config.dot.user.user} = {
        programs.obs-studio.plugins = with pkgs.obs-studio-plugins; [
          obs-gstreamer
        ];
      };
    };
}
