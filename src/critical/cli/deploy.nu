# TODO: scp age
# TODO: age location from configuration

def "main deploy" [host?: string] {
  let host = dot host pick --with-secrets $host
  if ($host.name == (open --raw /etc/hostname | str trim)) {
    (sudo nixos-rebuild switch
      --flake $"(dot flake)#($host.configuration)")
    sudo mkdir -p /root
    sudo chmod 700 /root
    $host.secrets."age-private" | sudo tee /root/host.scrt.key
    sudo chmod 400 /root/host.scrt.key
  } else {
    ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
      | ssh-add - \\
      && export SSHPASS='($host.secrets."pass-priv")' \\
      && sshpass -e deploy \\
        --skip-checks \\
        --interactive-sudo true \\
        --hostname ($host.ip) \\
        -- \\
        '(dot flake)#($host.configuration)'"
  }
}
