{
  machines.homeModules.anything-llm =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      prefix = "anythingllm";
      dataDir = "${config.xdg.dataHome}/${prefix}";

      version = "1.15.0";

      arch =
        {
          "x86_64-linux" = {
            url = "https://github.com/Mintplex-Labs/anything-llm/releases/download/v${version}/AnythingLLMDesktop.AppImage";
            sha256 = "0e4fc5786cde7c00a2265c937fefc155cf1926bc85f46abc056c59a9778069cb";
          };
          "aarch64-linux" = {
            url = "https://github.com/Mintplex-Labs/anything-llm/releases/download/v${version}/AnythingLLMDesktop-Arm64.AppImage";
            sha256 = "1b948c5090c398f03218d891fcbec8df7be0d0188cd1cf0bf2c881b5df9ac5f2";
          };
        }
        .${pkgs.stdenv.hostPlatform.system};

      src = pkgs.fetchurl {
        url = arch.url;
        sha256 = arch.sha256;
      };

      appimageContents = pkgs.appimageTools.extract {
        pname = "anything-llm";
        inherit version src;
      };

      package = pkgs.appimageTools.wrapType2 {
        pname = "anything-llm";
        inherit version src;

        runScript = ''
          sh -c '
          rm -f /etc/os-release
          cat > /etc/os-release << EOS
          NAME="Ubuntu"
          ID=ubuntu
          ID_LIKE=debian
          VERSION_ID="24.04"
          VERSION_CODENAME=noble
          PRETTY_NAME="Ubuntu 24.04 LTS"
          EOS
          export DISABLE_TELEMETRY=true
          case "''${XDG_SESSION_TYPE:-}" in
            wayland)
              exec appimage-exec.sh -w ${appimageContents} -- \
                --no-sandbox --enable-features=UseOzonePlatform \
                --ozone-platform=wayland --enable-wayland-ime "$@"
              ;;
            *)
              exec appimage-exec.sh -w ${appimageContents} -- \
                --no-sandbox "$@"
              ;;
          esac
          ' sh "$@"
        '';

        extraInstallCommands = ''
          install -Dm644 ${appimageContents}/anythingllm-desktop.desktop $out/share/applications/anything-llm.desktop
          substituteInPlace $out/share/applications/anything-llm.desktop \
            --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=anything-llm --user-data-dir=${dataDir} --no-sandbox %U'
        '';

        meta = {
          description = "The all-in-one AI app for chatting with documents, using AI Agents, and more";
          homepage = "https://anythingllm.com";
          license = lib.licenses.mit;
          mainProgram = "anything-llm";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        };
      };
    in
    lib.mkIf hardware.interface {
      home.packages = [
        package
      ];

      systemd.user.services.anythingllm = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit = {
          Description = "Anything LLM";
          After = [
            "tray.target"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe package} --user-data-dir=${dataDir}";
          Restart = "on-failure";
          WorkingDirectory = dataDir;
          Environment = "DISABLE_TELEMETRY=true";
          KillMode = "mixed";
          TimeoutStopSec = 15;
        };
      };
    };
}
