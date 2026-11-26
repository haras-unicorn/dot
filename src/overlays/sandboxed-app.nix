{ selfLib, ... }:

{
  self.overlays.overlays.sandboxed-app.value =
    final: _prev:
    let
      readOnlyPaths = [
        "/nix/store"
        "/run/current-system"
        "/usr"
        "/bin"
        "/sys"
        "/etc/passwd"
        "/etc/group"
        "/etc/nsswitch.conf"
        "/etc/hosts"
        "/etc/resolv.conf"
        "/etc/localtime"
        "/etc/ssl"
        "/etc/static"
        "/etc/fonts"
      ];

      readOnlyBinds = builtins.concatMap (path: [
        "--ro-bind-try"
        path
        path
      ]) readOnlyPaths;

      baseEnv = {
        PATH = "/run/current-system/sw/bin:/usr/bin:/bin";
        LANG = "C.UTF-8";
        SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        XDG_SESSION_TYPE = "wayland";
      };
    in
    {
      # NOTE: the app gets an empty home, a private /tmp, the network, the GPU
      # and the Wayland socket, and nothing else: no D-Bus (the session bus
      # can start user services, which is a way out of any sandbox), no audio,
      # and none of the environment of the session. The only things from the
      # home directory it sees are its own data directories, and the folders
      # it may read but not change. An AppImage made with appimageTools brings
      # its own bwrap, which nests inside this one
      makeSandboxedApp =
        {
          name,
          exe,
          home,
          dataDirs,
          readOnlyDirs ? [ ],
          workingDirectory ? null,
          env ? { },
        }:
        let
          environment = builtins.concatLists (
            final.lib.mapAttrsToList (variable: value: [
              "--setenv"
              variable
              value
            ]) (baseEnv // { HOME = home; } // env)
          );

          sandbox = [
            "--die-with-parent"
            "--new-session"
            "--unshare-all"
            "--share-net"
            "--clearenv"
          ]
          ++ readOnlyBinds
          ++ [
            "--dev"
            "/dev"
            "--proc"
            "/proc"
            "--tmpfs"
            "/tmp"
            "--tmpfs"
            home
          ]
          ++ selfLib.nvidiaBwrap
          ++ builtins.concatMap (directory: [
            "--bind"
            directory
            directory
          ]) dataDirs
          ++ builtins.concatMap (directory: [
            "--ro-bind"
            directory
            directory
          ]) readOnlyDirs
          ++ final.lib.optionals (workingDirectory != null) [
            "--chdir"
            workingDirectory
          ]
          ++ environment;
        in
        final.writeShellApplication {
          inherit name;
          runtimeInputs = [
            final.bubblewrap
            final.coreutils
          ];
          text = ''
            mkdir -p ${final.lib.escapeShellArgs (dataDirs ++ readOnlyDirs)}
            runtime="''${XDG_RUNTIME_DIR:?}"
            display="''${WAYLAND_DISPLAY:-wayland-1}"
            exec bwrap ${final.lib.escapeShellArgs sandbox} \
              --perms 0700 --tmpfs "$runtime" \
              --bind "$runtime/$display" "$runtime/$display" \
              --setenv XDG_RUNTIME_DIR "$runtime" \
              --setenv WAYLAND_DISPLAY "$display" \
              -- ${final.lib.escapeShellArg exe} "$@"
          '';
        };
    };
}
