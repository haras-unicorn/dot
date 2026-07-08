{
  machines.homeModules.kando =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      colors = config.lib.stylix.colors.withHashtag;

      menuColors = {
        "background-color" = colors.base00;
        "text-color" = colors.base05;
        "border-color" = colors.base03;
        "hover-color" = colors.base0C;
      };

      theme = "dot";

      kando-dmenu-py = pkgs.writeText "kando-dmenu.py" ''
        import asyncio, json, os, sys
        from datetime import datetime, timezone

        import websockets

        def log(area, msg):
            ts = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")
            for line in msg.split("\n"):
                print(f"[{ts}] [kando] [{area}]: {line}", file=sys.stderr, flush=True)

        async def main():
            choices = [line.strip() for line in sys.stdin if line.strip()]
            if not choices:
                log("startup", "no choices provided")
                sys.exit(1)

            log("startup", f"got {len(choices)} choices")

            ipc_path = os.path.expanduser("~/.config/kando/ipc-info.json")
            if not os.path.exists(ipc_path):
                log("ipc", f"ipc info not found at {ipc_path}")
                sys.exit(1)

            with open(ipc_path) as f:
                info = json.load(f)

            uri = f"ws://127.0.0.1:{info['port']}"
            log("ipc", f"connecting to {uri}")

            try:
                async with websockets.connect(uri) as ws:
                    menu = {
                        "type": "submenu",
                        "name": "Toolbelt",
                        "icon": "\U0001f527",
                        "iconTheme": "emoji",
                        "children": [
                            {"type": "simple-button", "name": c, "icon": "\U0001f539", "iconTheme": "emoji"}
                            for c in choices
                        ]
                    }
                    await ws.send(json.dumps({"type": "show-menu", "menu": menu}))
                    log("ipc", "menu sent, waiting for selection")

                    async for message in ws:
                        msg = json.loads(message)
                        log("ipc", f"received: {msg.get('type')}")

                        if msg.get("type") == "select-item":
                            path = msg.get("path", [])
                            if path and 0 <= path[0] < len(choices):
                                log("choice", f"selected: {choices[path[0]]}")
                                print(choices[path[0]])
                            break
                        elif msg.get("type") in ("cancel-menu", "error"):
                            log("choice", f"menu cancelled or error: {msg}")
                            break
            except Exception as e:
                log("error", str(e))
                sys.exit(1)

        asyncio.run(main())
      '';

      kando-dmenu = pkgs.writeShellApplication {
        name = "kando-dmenu";
        runtimeInputs = [ (pkgs.python3.withPackages (ps: [ ps.websockets ])) ];
        text = "exec python3 ${kando-dmenu-py}";
      };
    in
    lib.mkIf hardware.visual {
      dot.commands.kando = kando-dmenu;

      home.packages = [ pkgs.kando ];

      systemd.user.services.kando = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit = {
          Description = "Kando";
          After = [
            "tray.target"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray.target" ];
        };
        Service = {
          ExecStart = lib.getExe pkgs.kando;
          Restart = "on-failure";
          KillMode = "mixed";
          TimeoutStopSec = 15;
        };
      };

      xdg.configFile = {
        "kando/menu-themes/${theme}".source = "${pkgs.kando.src}/assets/menu-themes/clean-circle";
        "kando/config.json".text = builtins.toJSON {
          version = "2.1.0";
          locale = "auto";
          showIntroductionDialog = false;
          menuTheme = theme;
          menuThemeColors.dot = menuColors;
          enableVersionCheck = false;
          ignoreWriteProtectedConfigFiles = true;
          hardwareAcceleration = true;
        };
        # NOTE: https://github.com/kando-menu/kando-menu.github.io/blob/dbecdff42e3d4b8ac07e9821b183df11f770473d/src/content/docs/installation-on-linux.mdx#-niri
        "niri/config.kdl".text = ''
          window-rule {
            match title="Kando Menu"
            open-floating true
            focus-ring { off; }
            border { off; }
            shadow { off; }
            default-floating-position x=0 y=0
          }
        '';
      };
    };
}
