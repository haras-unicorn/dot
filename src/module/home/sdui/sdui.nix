{ pkgs, config, ... }:

let
  sdui-wrapped = pkgs.writeShellScriptBin "sdui-wrapped" ''
    export COMMANDLINE_ARGS="--listen --enable-insecure-extension-access --xformers --opt-sdp-no-mem-attention --no-half-vae --update-all-extensions";
    export TORCH_COMMAND="pip install torch==2.0.1+cu117 --extra-index-url https://download.pytorch.org/whl/cu117";
    export NO_TCMALLOC="True";

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
