{ pkgs, ... }:

let
  speak = pkgs.writeShellApplication {
    name = "speak";
    runtimeInputs = [ pkgs.piper-tts pkgs.jq pkgs.alsa-utils ];
    text = ''
      MODEL="$1"
      if [[ ! -f "$MODEL" ]]; then
        printf "I need a model to speak.\n"
        exit 1
      fi

      CONFIG="$1.json"
      if [[ ! -f "$CONFIG" ]]; then
        printf "The provided model does not have a config.\n"
        exit 1
      fi

      SAMPLERATE="$(jq .audio.sample_rate < "$CONFIG")"
      if [[ ! $SAMPLERATE =~ ^[0-9]+$ ]]; then
        printf "The provided model config does not include a sample rate.\n"
        exit 1
      fi

      cat | \
        piper --model "$MODEL" --config "$CONFIG" --output-raw --quiet | \
        aplay --rate "$SAMPLERATE" --format S16_LE --file-type raw --quiet
    '';
  };
in
{
  home.packages = with pkgs; [
    piper-tts
    speak
  ];
}
