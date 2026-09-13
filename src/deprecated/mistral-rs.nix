let
  makeModels = pkgs: {
    dia = pkgs.fetchurl {
      url = "https://huggingface.co/nari-labs/Dia-1.6B/resolve/main/model.safetensors";
      hash = "sha256-yroom2D219Hlj8dE9NwlquiJlfzKRr49BeIguXFIaiY=";
    };

    dieConfig = pkgs.fetchurl {
      url = "https://huggingface.co/nari-labs/Dia-1.6B/resolve/main/config.json";
      hash = "sha256-kUDoX9FbgtfyaMVoGkH7HeaFc+wga4fLOlhi/lxZjW4=";
    };

    diaDac = pkgs.fetchurl {
      name = "dac.safetensors";
      url = "https://huggingface.co/EricB/dac_44khz/resolve/main/model.safetensors";
      hash = "sha256-bkAWHz1cXaXC26ZL5o/C9pgyvHq0+nNsuYdkFpBfcYA=";
    };
  };
in
{
  self.lib.deprecated.nixosModules.mistral-rs =
    {
      config,
      lib,
      ...
    }:
    let
      cuda = config.dot.hardware.cuda;
    in
    lib.mkIf cuda { };

  self.lib.deprecated.homeModules.mistral-rs =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      cuda = osConfig.dot.hardware.cuda;

      package = pkgs.mistral-rs;

      node-describe = pkgs.writeShellApplication {
        name = "mistral-rs-node-describe";
        runtimeInputs = [
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .png)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          mistralrs run speech \
            --model-id "nari-labs/Dia-1.6B" \
            --output "$tmpout" \
            1>/dev/null
          cat "$tmpout"
        '';
      };
    in
    lib.mkIf cuda {
      dot.processing.nodes.mistral-rs-clone-speech = {
        note = "Clone speech";
        tags = [
          "clone"
          "speech"
          "generate"
          "generation"
          "text"
        ];
        inputs = [ "text/plain" ];
        output = "audio/wav";
        package = node-describe;
      };

      home.packages = [
        package
      ];
    };
}
