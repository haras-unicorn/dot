{ pkgs, config, ... }:

let
  aichat = pkgs.writeShellApplication {
    name = "aichat";
    runtimeInputs = [ pkgs.aichat ];
    text = ''
      cat <<EOF >${config.xdg.configHome}/aichat/config.yaml
        api_key: $(cat ${config.home.homeDirectory}/.openai/api.key)
        model: gpt-3.5-turbo # LLM model
        temperature: 1.0     # GPT temperature, between 0 and 2
        save: true           # Whether to save the message
        highlight: true      # Set false to turn highlight
        light_theme: false   # Whether to use a light theme
        wrap: 80             # Specify the text-wrapping mode (no, auto, <max-width>)
        wrap_code: true      # Whether wrap code block
        auto_copy: false     # Automatically copy the last output to the clipboard
        keybindings: vi      # REPL keybindings. values: emacs, vi
      EOF
      chmod 600 ${config.xdg.configHome}/aichat/config.yaml

      aichat "$@"
    '';

  };
in
{
  home.packages = [ aichat ];
}
