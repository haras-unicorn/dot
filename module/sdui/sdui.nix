{ pkgs, config, ... }:

let
  sdui = pkgs.mkScriptBin "sdui" ''
    #!${pkgs.stdenv.shell}
    set -eo pipefail

    if [[ ! -d ${config.xdg.dataHome}/stable-diffusion-webui ]]; then
      mkdir -p ${config.xdg.dataHome}
      git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ${config.xdg.dataHome}/stable-diffusion-webui
    fi
    if [[ ! -d ${config.xdg.dataHome}/automatic1111-webui-nix ]]; then
      mkdir -p ${config.xdg.dataHome}
      git clone https://github.com/virchau13/automatic1111-webui-nix ${config.xdg.dataHome}/automatic1111-webui-nix
    fi
    cp ${config.xdg.dataHome}/automatic1111-webui-nix/*.nix ${config.xdg.dataHome}/stable-diffusion-webui

    wd="$(pwd)"
    cd ${config.xdg.dataHome}/stable-diffusion-webui
    if [[ ! -x ./webui.sh ]]; then
      printf "Stable Diffusion WebUI script not present\n.Exiting...\n"
      exit 1
    fi

    nix develop --profile ./profile --command bash -c 'echo "Recorded profile"'

    git add .
    git commit -m "Flake" && echo "Flake commited" || echo "Flake already commited"
    git pull

    command=" \
      export COMMANDLINE_ARGS=\"--listen --enable-insecure-extension-access --xformers --opt-sdp-no-mem-attention --no-half-vae --update-all-extensions --skip-torch-cuda-test\" && \
      export TORCH_COMMAND=\"pip install torch==2.0.1+cu117 --extra-index-url https://download.pytorch.org/whl/cu117\" && \
      export NO_TCMALLOC=\"True\" && \
      ./webui.sh
    "
    echo "Running $command"
    nix develop ./profile --command bash -c "$command"

    cd "$wd"
  '';
in
{
  home.packages = [
    sdui
  ];
}
