{ ... }:

{
  self.overlays.overlays.opencode.value = final: prev: {
    opencode = final.writeShellApplication {
      name = "opencode";
      runtimeInputs = [
        prev.opencode
        prev.libuuid
      ];
      text = ''
        OPENCODE__PROVIDER__OPENROUTER__OPTIONS__SESSION_ID="$(uuidgen)"
        export OPENCODE__PROVIDER__OPENROUTER__OPTIONS__SESSION_ID
        DOT_MCP_ROOT="$(pwd -P)"
        export DOT_MCP_ROOT
        export OPENCODE_ENABLE_EXA=1
        opencode "$@"
      '';
    };
  };
}
