{
  nixpkgs,
  pkgs,
  lib,
  config,
  ...
}:

# TODO: fix 340
# FIXME: https://github.com/NixOS/nixpkgs/issues/306276

(
  let
    user = config.dot.user;

    hasNvidia = config.dot.hardware.graphics.driver == "nvidia";
    version = config.dot.hardware.graphics.version;
  in
  {
    branch.nixosModule.nixosModule = lib.mkIf hasNvidia {
      boot.initrd.availableKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
      ];
      boot.kernelParams = [
        "nvidia_drm.modeset=1"
        "nvidia_drm.fbdev=1"
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      ];
      boot.kernelModules = [
        "nvidia_uvm"
      ];

      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia.modesetting.enable = true;
      hardware.nvidia.nvidiaSettings = true;
      hardware.nvidia.open = config.dot.hardware.graphics.open;
      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages."${version}";

      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      hardware.graphics.extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libvdpau-va-gl
      ];
      hardware.graphics.extraPackages32 = with pkgs.driversi686Linux; [
        libvdpau-va-gl
      ];

      hardware.nvidia-container-toolkit.enable = true;

      environment.systemPackages = with pkgs; [
        libva
        libvdpau
        vdpauinfo # NOTE: vdpauinfo
        libva-utils # NOTE: vainfo
        vulkan-tools # NOTE: vulkaninfo
        glxinfo # NOTE: glxinfo and eglinfo
      ];

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia"; # NOTE: hardware acceleration
        VDPAU_DRIVER = "va_gl"; # NOTE: hardware acceleration
        GBM_BACKEND = "nvidia-drm"; # NOTE: wayland buffer api
        WLR_RENDERER = "gles2"; # NOTE: wayland roots compositor renderer
        __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # NOTE: offload opengl workloads to nvidia

        NVD_BACKEND = "direct"; # NOTE: nvidia-vaapi-driver backend
        __GL_GSYNC_ALLOWED = "1"; # NOTE: nvidia g-sync
        __GL_VRR_ALLOWED = "1"; # NOTE: nvidia g-sync
      };

      users.users.${user}.extraGroups = [
        "video"
      ];
    };
  }
)
// (
  let
    openUrl = "https://web.archive.org/web/20241006015348/https://github.com/NVIDIA/open-gpu-kernel-modules";
    legacyUrl = "https://web.archive.org/web/20240928225313/https://www.nvidia.com/en-us/drivers/unix/legacy-gpu";

    mkNvidia = pkgs: rec {
      openHtml = pkgs.fetchurl {
        name = "nvidia-open-html";
        url = openUrl;
      };
      legacyHtml = pkgs.fetchurl {
        name = "nvidia-legacy-html";
        url = legacyUrl;
      };

      mkLegacyScript =
        curr: prev:
        pkgs.writeTextFile {
          name = "nvidia-legacy-${curr}-script";
          text = ''
            $in
              | lines
              | skip until { |x| $x =~ "${curr}.xx" }
              | take until { |x| $x =~ "${prev}.xx" }
              | skip 12
              | drop 4
              | enumerate
              | where ($it.index mod 5) == 0
              | each { |x| $x.item }
              | str replace -r ".*<td.*>([0-9A-F]+).*</td>.*" "$1"
              | uniq
              | str join "\n"
          '';
        };
      openScript = pkgs.writeTextFile {
        name = "nvidia-open-script";
        text = ''
          $in
            | lines
            | where $it =~ "<td>([0-9A-F]+ ?){1,3}</td>"
            | str replace -r "<td>([0-9A-F]+).*</td>" "$1"
            | uniq
            | str join "\n"
        '';
      };
      mkExpr =
        name: html: script:
        pkgs.lib.splitString "\n" (
          builtins.readFile (
            "${
              pkgs.runCommand "nvidia-${name}-text"
                {
                  buildInputs = [ pkgs.nushell ];
                }
                ''
                  mkdir $out
                  cat ${html} | nu --stdin -c '${builtins.readFile script}' > $out/result
                ''
            }/result"
          )
        );

      # legacy340 = mkExpr "legacy-340" legacyHtml (mkLegacyScript "340" "304");
      legacy340 = [ ];
      legacy470 = mkExpr "legacy-470" legacyHtml (mkLegacyScript "470" "390");
      legacy390 = mkExpr "legacy-390" legacyHtml (mkLegacyScript "390" "340");
      open = mkExpr "open" openHtml openScript;
    };
  in
  {
    flake.lib.nvidia.mkComputed =
      pkgs:
      let
        nvidia = mkNvidia pkgs;
      in
      {
        legacy340 = nvidia.legacy340;
        legacy390 = nvidia.legacy390;
        legacy470 = nvidia.legacy470;
        open = nvidia.open;

        legacy = builtins.concatLists [
          nvidia.legacy340
          nvidia.legacy390
          nvidia.legacy470
        ];
      };

    flake.lib.nvidia.frozen =
      let
        legacy340 = [ ];

        legacy390 = [
          "06C0"
          "06C4"
          "06CA"
          "06CD"
          "06D1"
          "06D2"
          "06D8"
          "06D9"
          "06DA"
          "06DC"
          "06DD"
          "06DE"
          "06DF"
          "0DC0"
          "0DC4"
          "0DC5"
          "0DC6"
          "0DCD"
          "0DCE"
          "0DD1"
          "0DD2"
          "0DD3"
          "0DD6"
          "0DD8"
          "0DDA"
          "0DE0"
          "0DE1"
          "0DE2"
          "0DE3"
          "0DE4"
          "0DE5"
          "0DE7"
          "0DE8"
          "0DE9"
          "0DEA"
          "0DEB"
          "0DEC"
          "0DED"
          "0DEE"
          "0DEF"
          "0DF0"
          "0DF1"
          "0DF2"
          "0DF3"
          "0DF4"
          "0DF5"
          "0DF6"
          "0DF7"
          "0DF8"
          "0DF9"
          "0DFA"
          "0DFC"
          "0"
          "0E3A"
          "0E3B"
          "0F00"
          "0F01"
          "0F02"
          "0F03"
          "1040"
          "1042"
          "1048"
          "1049"
          "104A"
          "104B"
          "104C"
          "1050"
          "1051"
          "1052"
          "1054"
          "1055"
          "1056"
          "1057"
          "1058"
          "1059"
          "105A"
          "105B"
          "107C"
          "107D"
          "1080"
          "1081"
          "1082"
          "1084"
          "1086"
          "1087"
          "1088"
          "1089"
          "108B"
          "1091"
          "1094"
          "1096"
          "109A"
          "109B"
          "1140"
          "1200"
          "1201"
          "1203"
          "1205"
          "1206"
          "1207"
          "1208"
          "1210"
          "1211"
          "1212"
          "1213"
          "1241"
          "1243"
          "1244"
          "1245"
          "1246"
          "1247"
          "1248"
          "1249"
          "124B"
          "124D"
          "1251"
        ];

        legacy470 = [
          "0FC6"
          "0FC8"
          "0FC9"
          "0FCD"
          "0FCE"
          "0FD1"
          "0FD2"
          "0FD3"
          "0FD4"
          "0FD5"
          "0FD8"
          "0FD9"
          "0FDF"
          "0FE0"
          "0FE1"
          "0FE2"
          "0FE3"
          "0FE4"
          "0FE9"
          "0FEA"
          "0FEC"
          "0FED"
          "0FEE"
          "0FF6"
          "0FF8"
          "0FF9"
          "0FFA"
          "0FFB"
          "0FFC"
          "0FFD"
          "0FFE"
          "0FFF"
          "1001"
          "1004"
          "1005"
          "1007"
          "1008"
          "100A"
          "100C"
          "1021"
          "1022"
          "1023"
          "1024"
          "1026"
          "1027"
          "1028"
          "1029"
          "102A"
          "102D"
          "103A"
          "103C"
          "1180"
          "1183"
          "1184"
          "1185"
          "1187"
          "1188"
          "1189"
          "118A"
          "118E"
          "118F"
          "1193"
          "1194"
          "1195"
          "1198"
          "1199"
          "119A"
          "119D"
          "119E"
          "119F"
          "11A0"
          "11A1"
          "11A2"
          "11A3"
          "11A7"
          "11B4"
          "11B6"
          "11B7"
          "11B8"
          "11BA"
          "11BC"
          "11BD"
          "11BE"
          "11C0"
          "11C2"
          "11C3"
          "11C4"
          "11C5"
          "11C6"
          "11C8"
          "11CB"
          "11E0"
          "11E1"
          "11E2"
          "11E3"
          "11FA"
          "11FC"
          "1280"
          "1281"
          "1282"
          "1284"
          "1286"
          "1287"
          "1288"
          "1289"
          "128B"
          "1290"
          "1291"
          "1292"
          "1293"
          "1295"
          "1296"
          "1298"
          "1299"
          "129A"
          "12B9"
          "12BA"
        ];

        open = [
          "1E02"
          "1E04"
          "1E07"
          "1E30"
          "1E36"
          "1E78"
          "1E81"
          "1E82"
          "1E84"
          "1E87"
          "1E89"
          "1E90"
          "1E91"
          "1E93"
          "1EB0"
          "1EB1"
          "1EB5"
          "1EB6"
          "1EC2"
          "1EC7"
          "1ED0"
          "1ED1"
          "1ED3"
          "1EF5"
          "1F02"
          "1F03"
          "1F06"
          "1F07"
          "1F08"
          "1F0A"
          "1F10"
          "1F11"
          "1F12"
          "1F14"
          "1F15"
          "1F36"
          "1F42"
          "1F47"
          "1F50"
          "1F51"
          "1F54"
          "1F55"
          "1F76"
          "1F82"
          "1F83"
          "1F91"
          "1F95"
          "1F96"
          "1F97"
          "1F98"
          "1F99"
          "1F9C"
          "1F9D"
          "1F9F"
          "1FA0"
          "1FB0"
          "1FB1"
          "1FB2"
          "1FB6"
          "1FB7"
          "1FB8"
          "1FB9"
          "1FBA"
          "1FBB"
          "1FBC"
          "1FDD"
          "1FF0"
          "1FF2"
          "1FF9"
          "20B0"
          "20B2"
          "20B3"
          "20B5"
          "20B6"
          "20B7"
          "20BD"
          "20F1"
          "20F3"
          "20F5"
          "20F6"
          "20FD"
          "2182"
          "2184"
          "2187"
          "2188"
          "2191"
          "2192"
          "21C4"
          "21D1"
          "2203"
          "2204"
          "2206"
          "2207"
          "2208"
          "220A"
          "220D"
          "2216"
          "2230"
          "2231"
          "2232"
          "2233"
          "2235"
          "2236"
          "2237"
          "2238"
          "2321"
          "2322"
          "2324"
          "2329"
          "2330"
          "2331"
          "2335"
          "2339"
          "233A"
          "2342"
          "2414"
          "2420"
          "2438"
          "2460"
          "2482"
          "2484"
          "2486"
          "2487"
          "2488"
          "2489"
          "248A"
          "249C"
          "249D"
          "24A0"
          "24B0"
          "24B1"
          "24B6"
          "24B7"
          "24B8"
          "24B9"
          "24BA"
          "24BB"
          "24C7"
          "24C9"
          "24DC"
          "24DD"
          "24E0"
          "24FA"
          "2503"
          "2504"
          "2507"
          "2508"
          "2520"
          "2521"
          "2523"
          "2531"
          "2544"
          "2560"
          "2563"
          "2571"
          "2582"
          "2584"
          "25A0"
          "25A2"
          "25A5"
          "25A6"
          "25A7"
          "25A9"
          "25AA"
          "25AB"
          "25AC"
          "25AD"
          "25B0"
          "25B2"
          "25B6"
          "25B8"
          "25B9"
          "25BA"
          "25BB"
          "25BC"
          "25BD"
          "25E0"
          "25E2"
          "25E5"
          "25EC"
          "25ED"
          "25F9"
          "25FA"
          "25FB"
          "2684"
          "2685"
          "2689"
          "26B1"
          "26B2"
          "26B3"
          "26B5"
          "26B9"
          "26BA"
          "2702"
          "2704"
          "2705"
          "2709"
          "2717"
          "2730"
          "2757"
          "2770"
          "2782"
          "2783"
          "2786"
          "2788"
          "27A0"
          "27B0"
          "27B1"
          "27B2"
          "27B6"
          "27B8"
          "27BA"
          "27BB"
          "27E0"
          "27FB"
          "2803"
          "2805"
          "2808"
          "2820"
          "2822"
          "2838"
          "2860"
          "2882"
          "28A0"
          "28A1"
          "28B0"
          "28B8"
          "28B9"
          "28BA"
          "28BB"
          "28E0"
          "28E1"
          "28F8"
        ];
      in
      {
        inherit
          legacy340
          legacy390
          legacy470
          open
          ;

        legacy = builtins.concatLists [
          legacy340
          legacy390
          legacy470
        ];
      };
  }
)
