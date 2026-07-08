{
  machines.homeModules.stable-diffusion-cpp =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;

      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "stable-diffusion-cpp";
        paths = [ pkgs.stable-diffusion-cpp ];
        pathsToLink = [ "/bin" ];
      };

      clip_g = pkgs.fetchurl {
        url = "https://huggingface.co/second-state/stable-diffusion-3.5-medium-GGUF/resolve/main/clip_g-Q4_0.gguf";
        hash = "sha256-wUJBEUfha3xLnMH12XfL5ZYQRDXXb95HFy09NcXli7g=";
      };

      clip_l = pkgs.fetchurl {
        url = "https://huggingface.co/second-state/stable-diffusion-3.5-medium-GGUF/resolve/main/clip_l-Q4_0.gguf";
        hash = "sha256-9a2IrirJJOtKwCmLd6+jBLXmAU/AxBKPDj30D9/MD4o=";
      };

      model = pkgs.fetchurl {
        url = "https://huggingface.co/tensorart/stable-diffusion-3.5-medium-turbo/resolve/main/sd3.5m_turbo-Q4_K_M.gguf";
        hash = "sha256-PDeTgTRNKis+49ehvJf30eWPqVxrUYf7SLPORG+Z8Xs=";
      };

      t5xxl = pkgs.fetchurl {
        url = "https://huggingface.co/second-state/stable-diffusion-3.5-medium-GGUF/resolve/main/t5xxl-Q4_0.gguf";
        hash = "sha256-mHukfBWLiQwnT3j9NTJEGfUJQehGpJeJ8Jd+n+nZerc=";
      };

      vae = pkgs.fetchurl {
        url = "https://huggingface.co/tensorart/stable-diffusion-3.5-medium-turbo/resolve/main/vae/diffusion_pytorch_model.safetensors";
        hash = "sha256-j1MwSnkzW1XhPsUPY+UVf+5N6y8w1frgZU4rJlPBCdw=";
      };

      node-generate = pkgs.writeShellApplication {
        name = "stable-diffusion-cpp-node-generate";
        runtimeInputs = [
          pkgs.llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .png)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          sd-cli \
            --diffusion-model "${model}" \
            --clip_g "${clip_g}" \
            --clip_l "${clip_l}" \
            --t5xxl "${t5xxl}" \
            --vae "${vae}" \
            --diffusion-fa \
            --mmap \
            --offload-to-cpu \
            --prompt "$(cat "$tmpin")" \
            --height 1024 \
            --width 1024 \
            --cfg-scale 1.5 \
            --slg-scale 2.5 \
            --steps 8 \
            --sampling-method euler \
            --output "$tmpout" \
            1>/dev/null
          cat "$tmpout"
        '';
      };
    in
    lib.mkIf cuda {
      dot.processing.nodes.stable-diffusion-cpp-generate = {
        note = "Generate an image";
        tags = [
          "image"
          "generate"
          "generation"
          "text"
        ];
        inputs = [ "text/plain" ];
        output = "image/png";
        package = node-generate;
      };

      dot.ai.models.sd-3-5-turbo.files = [
        model
        clip_g
        clip_l
        t5xxl
        vae
      ];

      home.packages = [
        package
      ];
    };
}
