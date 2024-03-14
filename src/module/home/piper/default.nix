{ pkgs, config, ... }:

let
  speak = pkgs.writeShellApplication {
    name = "speak";
    runtimeInputs = [ pkgs.piper-tts pkgs.jq pkgs.alsa-utils ];
    text = ''
      config=""
      command="piper --output-raw --quiet"
      while IFS= read -r line; do
        command+=" $line"

        if [[ "$line" == --config* ]]; then
          config="$${line#--config }"
        fi
      done < "${config.home.homeDirectory}/speak/options"
      echo "$command"

      if [[ ! -f "$config" ]]; then 
        printf "The options file doesn't contain a valid config parameter.\n"
        exit 1
      fi

      samplerate="$(jq .audio.sample_rate < "$config")"
      if [[ ! $samplerate =~ ^[0-9]+$ ]]; then
        printf "The provided model config does not include a sample rate.\n"
        exit 1
      fi

      cat | $command 2>/dev/null | aplay --rate "$samplerate" --format S16_LE --file-type raw --quiet
    '';
  };
in
{
  home.packages = with pkgs; [
    piper-tts
    speak
  ];
}
