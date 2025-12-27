#!/usr/bin/env nu

# TODO: load hosts through nix

let self = [ $env.FILE_PWD "hosts.nu" ] | path join
let root = $env.FILE_PWD | path dirname
let artifacts = [ $root "artifacts" ] | path join
let flake = $"path:($root)"

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
    let spec = $spec | from json | update exports { [] } | to json
    $spec | rumor from-stdin json --stay --keep --dry-run --nosandbox --very-verbose
  }
}

def "main backup" [dest?: path, host?: string] {
  let dest = if ($dest | is-empty) { "backup.tar.gzip.age" } else { $dest }
  let host = pick hosts false true $host | first
  let shared = vault kv get -format=json "kv/dot/shared/current"
    | from json
    | get data.data

  let drv = (nix build
    --print-out-paths
    --no-link
    $"path:($root)#packages.($host.system).backup")

  print "Built derivation..."

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && nix-copy-closure --to ($host.ip) ($drv)"

  print "Copied closure..."

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && ssh ($host.ip) ($drv)/bin/backup '($host.secrets."pass-priv")' '($shared."backup-age-public")' '~/backup.tar.gzip.age'"

  print "Created backup..."

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && scp ($host.ip):~/backup.tar.gzip.age '($dest)'"

  print "Moved backup..."
}

def "main image" [host?: string, format?: string] {
  let host = pick hosts false true $host | first
  let format = if $format == null { "sd-aarch64" } else { $format }

  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  let raw = (nixos-generate
    --show-trace
    --system $host.system
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
        generator: "nebula-cert"
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
  } | to json | rumor from-stdin json --stay --keep --dry-run --nosandbox --very-verbose
}

def "pick hosts" [all: bool, with_secrets: bool, name?: string] {
  mut hosts = nix eval --json --impure --expr $"
    let
      lib = \(import <nixpkgs> { }\).lib;
      configs = \(builtins.getFlake path:($root)\).nixosConfigurations;
    in
      builtins.attrValues
        \(builtins.mapAttrs
          \(configuration: config:
            let
              split = lib.drop 1
                \(lib.splitString "-" configuration\);
              name = builtins.concatStringsSep "-"
                \(lib.dropEnd 2 split\);
              system = builtins.concatStringsSep "-"
                \(lib.takeEnd 2 split\);
            in {
              inherit configuration name system;
              ip = config.config.dot.host.ip;
            }\)
          configs\)
  " | from json

  if ($name == null) and not ($all) {
    let wanted = (gum choose --header "Pick host name:" ...($hosts | get name))
    $hosts = $hosts | where $it.name == $wanted
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
