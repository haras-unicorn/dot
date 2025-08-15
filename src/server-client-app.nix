{ lib, ... }:

{
  flake.lib.serverClientApp =
    pkgs:
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
    pkgs.writeShellApplication (
      (builtins.removeAttrs args [
        "display"
        "servers"
        "waits"
        "speed"
        "client"
      ])
      // {
        runtimeInputs = runtimeInputs ++ [ pkgs.zenity ];
        text = ''
          ${lib.concatStringsSep "\n" (
            lib.imap0 (i: _: ''
              port${toString i}=$(shuf -i 32768-65535 -n 1)
              while ss -tulwn | grep -q ":$port${toString i} "; do
                port${toString i}=$(shuf -i 32768-65535 -n 1)
              done
            '') servers
          )}
            
          systemd-run --user --scope --unit=${name}-servers \
            sh -c "${lib.concatStringsSep " & " servers} & wait" &
            
          (
            progress=0
            while ! (${lib.concatStringsSep " && " (map (x: "${x} > /dev/null") waits)}); do
              sleep ${toString speed}
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
}
