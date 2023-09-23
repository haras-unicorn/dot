{ pkgs, config, ... }:

let
  sdui-wrapped = pkgs.writeShellScriptBin "sdui-wrapped" ''
    args="--listen"
    args="$args --no-half-vae"
    args="$args --xformers"
    args="$args --opt-sdp-no-mem-attention"
    args="$args --enable-insecure-extension-access"
    args="$args --update-all-extensions"
    export COMMANDLINE_ARGS="$args"
    echo "$COMMANDLINE_ARGS"

    torchv="2.0.1+cu118"
    torchurl="https://download.pytorch.org/whl/cu118"
    export TORCH_COMMAND="pip install torch==$torchv --extra-index-url $torchurl"
    echo "$TORCH_COMMAND"

    export NO_TCMALLOC="True"

    if [[ ! -x "${config.xdg.dataHome}/stable-diffusion-webui/webui.sh" ]]; then
      printf "Stable Diffusion WebUI script not present\n.Exiting...\n"
      exit 1
    fi

    "${config.xdg.dataHome}/stable-diffusion-webui/webui.sh"
  '';

  sdui = pkgs.writeShellScriptBin "sdui" ''
    if [[ ! -d ${config.xdg.dataHome}/stable-diffusion-webui ]]; then
      mkdir -p ${config.xdg.dataHome}
      git clone --depth 1 \
        https://github.com/AUTOMATIC1111/stable-diffusion-webui \
        ${config.xdg.dataHome}/stable-diffusion-webui
    fi

    if [[ ! -d ${config.xdg.dataHome}/automatic1111-webui-nix ]]; then
      mkdir -p ${config.xdg.dataHome}
      git clone --depth 1 \
         https://github.com/virchau13/automatic1111-webui-nix \
        ${config.xdg.dataHome}/automatic1111-webui-nix
    fi

    # TODO: use flake from webui-nix without copying and cd
    cp \
      "${config.xdg.dataHome}/automatic1111-webui-nix"/*.nix \
      "${config.xdg.dataHome}/stable-diffusion-webui"
    cp \
      "${config.xdg.dataHome}/automatic1111-webui-nix"/flake.lock \
      "${config.xdg.dataHome}/stable-diffusion-webui"
    wd="$(pwd)"
    cd "${config.xdg.dataHome}/stable-diffusion-webui"
    nix flake lock
    git add .

    nix develop --command "${sdui-wrapped}/bin/sdui-wrapped"
    cd "$wd"
  '';
in
{
  home.packages = [
    sdui-wrapped
    sdui
  ];
}
