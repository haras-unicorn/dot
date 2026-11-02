{
  self.overlays.overlays.server-client-app.value = final: _prev: {
    makeServerClientApp =
      {
        name,
        display ? name,
        servers,
        waits,
        speed ? 1,
        client,
        runtimeInputs ? [ ],
        ...
      }@args:
      final.writeShellApplication (
        (builtins.removeAttrs args [
          "display"
          "servers"
          "waits"
          "speed"
          "client"
        ])
        // {
          runtimeInputs = runtimeInputs ++ [
            final.zenity
          ];
          text = ''
            ${final.lib.concatStringsSep "\n" (
              final.lib.imap0 (i: _: ''
                port${builtins.toString i}=$(shuf -i 32768-65535 -n 1)
                while ss -tulwn | grep -q ":$port${builtins.toString i} "; do
                  port${builtins.toString i}=$(shuf -i 32768-65535 -n 1)
                done
              '') servers
            )}

            systemd-run --user --scope --unit=${name}-servers \
              sh -c "${final.lib.concatStringsSep " & " servers} & wait" &

            (
              progress=0
              while ! (${final.lib.concatStringsSep " && " (builtins.map (x: "${x} > /dev/null") waits)}); do
                sleep ${builtins.toString speed}
                progress=$(( (progress + 100) / 2 ))
                [ $progress -ge 99 ] && progress=99
                echo "$progress"
              done
              echo 100
            ) | zenity --progress --no-cancel --auto-close \
              --title="Starting ${display}" --text="Initializing server..."

            ${client} || echo "Client exited with non-zero exit code"

            systemctl stop --user ${name}-servers.scope
          '';
        }
      );
  };
}
