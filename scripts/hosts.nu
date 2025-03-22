#!/usr/bin/env nu

let self = [ $env.FILE_PWD "hosts.nu" ] | path join
let root = $env.FILE_PWD | path dirname
let artifacts = [ $root "artifacts" ] | path join
let hosts = [ $root "assets" "hosts.toml" ] | path join
let flake = $"git+file:($root)"

def main [] {
  nu -c $"($self) --help"
}

def "main secrets" [host?: string] {
  let host = (pick host $host)

  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  $host.spec | rumor stdin json --stay
}

def "main image" [host?: string, format?: string] {
  let host = (pick host $host)
  let format = if $format == null { "sd-aarch64" } else { $format }

  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  let raw = (nixos-generate
    --system $host.system.nixpkgs.system
    --format $format
    --flake $"($root)#($host.configuration)")

  let compressed = ls ($raw
    | path dirname --num-levels 2
    | path join "sd-image")
    | get name
    | first
  unzstd $compressed -o image.img
  chmod 644 image.img

  let age = $host.secrets."age-private"
    | str replace -a "\\" "\\\\"
    | str replace -a "\n" "\\n"
    | str replace -a "\"" "\\\""

  let commands = $"run
mount /dev/sda2 /
mkdir-p /root
chmod 700 /root
write /root/host.scrt.key \"($age)\"
chmod 400 /root/host.scrt.key
exit"

  echo $commands | guestfish --rw -a image.img
}

def "main ssh" [host?: string] {
  let host = (pick host $host)

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && ssh ($host.ip)"
}

def "main pass" [host?: string] {
  let host = (pick host $host)
  $host.secrets."pass-private"
}

def "main deploy" [host?: string] {
  let host = (pick host $host)
  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && export SSHPASS='($host.secrets."pass-private")' \\
    && sshpass -e deploy \\
      --skip-checks \\
      --interactive-sudo true \\
      --hostname ($host.ip) \\
      -- \\
      '($root)#($host.configuration)'"
}

def "pick host" [name?: string] {
  mut name = $name

  let hosts = (open --raw $hosts) | from toml | get hosts

  if $name == null {
    let hostnames = $hosts | get name 
    $name = (gum choose --header "Pick host name:" ...($hostnames))
  }

  let host = $hosts
    | where $it.name == $name
    | first
  let secrets = vault kv get -format=json $"kv/dot/host/($name)/current"
    | from json
    | get ?.data?.data
  let configuration = $"($name)-($host.system.nixpkgs.system)"
  let spec = nix eval --json $".#rumor.($configuration)"| from json
  $host
    | insert secrets $secrets
    | insert configuration $configuration
    | insert spec $spec
}
