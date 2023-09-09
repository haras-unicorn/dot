{ pkgs, config, ... }:

let
  tui = pkgs.writeScriptBin "tui" ''
    #!${pkgs.stdenv.shell}
    set -eo pipefail

    if [[ ! -d ${config.xdg.dataHome}/text-generation-webui ]]; then
      mkdir -p ${config.xdg.dataHome}
      git clone https://github.com/oobabooga/text-generation-webui ${config.xdg.dataHome}/text-generation-webui
    fi
    if [[ ! -d ${config.xdg.dataHome}/automatic1111-webui-nix ]]; then
      mkdir -p ${config.xdg.dataHome}
      git clone https://github.com/virchau13/automatic1111-webui-nix ${config.xdg.dataHome}/automatic1111-webui-nix
    fi
    cp ${config.xdg.dataHome}/automatic1111-webui-nix/*.nix ${config.xdg.dataHome}/text-generation-webui

    wd="$(pwd)"
    cd ${config.xdg.dataHome}/text-generation-webui

    nix develop --profile ./profile --command bash -c 'echo "Recorded profile"'
    cat <<END > ./webui.sh
      #!/usr/bin/env bash
      set -eo pipefail

      printf "Hello world!"
    END
    chmod +x ./webui.sh

    git add .
    git update-index --chmod=+x ./webui.sh
    git commit -m "Flake" && echo "Flake commited" || echo "Flake already commited"
    git pull

    echo "Running ./webui.sh"
    nix develop ./profile --command bash ./webui.sh

    cd "$wd"
  '';
in
{
  home.packages = [
    tui
  ];
}
