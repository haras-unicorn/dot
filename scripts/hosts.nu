#!/usr/bin/env nu

# TODO: load hosts through nix

let self = [ $env.FILE_PWD "hosts.nu" ] | path join
let root = $env.FILE_PWD | path dirname
let artifacts = [ $root "artifacts" ] | path join
let hosts = [ $root "src" "hosts" "hosts.toml" ] | path join
let flake = $"git+file:($root)"

let nebula_base_template = "
firewall:
  inbound:
    - host: any
      port: any
      proto: any
  outbound:
    - host: any
      port: any
      proto: any
listen:
  host: '[::]'
  port: 0
pki:
  ca: \"{{CA_PUBLIC}}\"
  key: \"{{CERT_PRIVATE}}\"
  cert: \"{{CERT_PUBLIC}}\"
handshakes:
  try_interval: 1s
static_map:
  cadence: 5m
  lookup_timeout: 10s
preferred_ranges: [ '192.168.1.0/24' ]
" | str trim

def main [] {
  nu -c $"($self) --help"
}

def "main secrets" [host?: string, --all] {
  let hosts = pick hosts $all false $host

  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  for host in $hosts {
    let spec = nix eval --json $".#rumor.($host.configuration)"
    $spec | rumor stdin json --stay
  }
}

def "main image" [host?: string, format?: string] {
  let host = pick hosts false true $host | first
  let format = if $format == null { "sd-aarch64" } else { $format }

  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  let raw = (nixos-generate
    --show-trace
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

def "main ssh" [host?: string, ip?: string] {
  let host = pick hosts false true $host | first
  let ip = if ($ip == null) { $host.ip } else { $ip }

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && ssh -t ($ip) motd-wrap nu"
}

def "main scp-here" [from: string, to: string, host?: string, ip?: string] {
  let host = pick hosts false true $host | first
  let ip = if ($ip == null) { $host.ip } else { $ip }

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && scp ($ip):($from) ($to)"
}

def "main scp-there" [from: string, to: string, host?: string, ip?: string] {
  let host = pick hosts false true $host | first
  let ip = if ($ip == null) { $host.ip } else { $ip }

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && scp ($from) ($ip):($to)"
}

def "main pass" [host?: string] {
  let host = pick hosts false true $host | first
  $host.secrets."pass-priv"
}

def "main deploy" [host?: string] {
  let host = pick hosts false true $host | first

  if ($host.name == (open --raw /etc/hostname | str trim)) {
    (sudo nixos-rebuild switch
      --flake $"($root)#($host.configuration)")
    sudo mkdir -p /root
    sudo chmod 700 /root
    $host.secrets."age-private" | sudo tee /root/host.scrt.key
    sudo chmod 400 /root/host.scrt.key
  } else {
    # TODO: scp age
    ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
      | ssh-add - \\
      && export SSHPASS='($host.secrets."pass-priv")' \\
      && sshpass -e deploy \\
        --skip-checks \\
        --interactive-sudo true \\
        --hostname ($host.ip) \\
        -- \\
        '($root)#($host.configuration)'"
  }
}

def "main nebula" [ip: string, --host: string] {
  let host = if $host == null {
      open --raw /etc/hostname
    } else {
      $host
    } | str trim

  let shared = vault kv get -format=json "kv/dot/shared/current"
    | from json
    | get data.data

  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  {
    imports: [
      {
        importer: "vault-file"
        arguments: {
          path: "kv/dot/shared"
          file: "nebula-ca-private"
        }
      }
      {
        importer: "vault-file"
        arguments: {
          path: "kv/dot/shared"
          file: "nebula-ca-public"
        }
      }
      {
        importer: "vault"
        arguments: {
          path: $"kv/dot/external/($host)"
          allow_fail: true
        }
      }
    ]
    generations: [
      {
        generator: "nebula"
        arguments: {
          ca_private: "nebula-ca-private"
          ca_public: "nebula-ca-public"
          name: $host
          ip: $"($ip)/16"
          private: $"($host)-nebula-private"
          public: $"($host)-nebula-public"
        }
      }
      {
        generator: "moustache"
        arguments: {
          name: $"($host)-nebula-config"
          renew: true
          variables: {
            CA_PUBLIC: "nebula-ca-public"
            CERT_PRIVATE: $"($host)-nebula-private"
            CERT_PUBLIC: $"($host)-nebula-public"
          }
          template: ($nebula_base_template
            + "\n"
            + $shared.nebula-non-lighthouse)
        }
      }
    ]
    exports: [
      {
        exporter: "vault"
        arguments: {
          path: $"kv/dot/external/($host)"
        }
      }
    ]
  } | to json | rumor stdin json --stay
}

def "pick hosts" [all: bool, with_secrets: bool, name?: string] {
  mut hosts = open $hosts | get hosts

  if ($name == null) and not ($all) {
    let wanted = (gum choose --header "Pick host name:" ...($hosts | get name ))
    $hosts = $hosts | where $it.name == $wanted
  }

  $hosts = $hosts | each { |host|
    let configuration = $"($host.name)-($host.system.nixpkgs.system)"
    $host | insert configuration $configuration
  }

  if not $with_secrets {
    return $hosts
  }

  $hosts | each { |host|
    let key = $"kv/dot/host/($host.name)/current"
    let secrets = vault kv get -format=json $key
      | from json
      | get data.data
    $host | insert secrets $secrets
  }
}
