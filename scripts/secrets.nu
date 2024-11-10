#!/usr/bin/env nu

def "main" [] {
  help main
}

# create secrets shared between hosts
def "main shared" [] {
  main vpn ca shared
}

# create secrets for the nebula lighthouse host
def "main host lighthouse" [
  --name: string, # name of the host
] {
  main ddns $name
  main vpn host $name shared
  main vpn lighthouse $name true
  main ssh $name
  main pass $name
  main sops $name
}

# create secrets for a regular host
def "main host regular" [
  --name: string, # name of the host
  --ip: string, # ip of the host in the nebula vpn
] {
  main vpn host $name shared
  main vpn lighthouse $name false
  main ssh $name
  main pass $name
  main sops $name
}

# create the nebula vpn ca
#
# outputs:
#   ./name.vpn.pub
#   ./name.vpn
def "main vpn ca" [name: string = "ca"] {
  nebula-cert ca -name $name -duration $"(365 * 24 * 100)h"

  mv $"ca.crt" $"($name).vpn.pub"
  chmod 644 $"($name).vpn.pub"

  mv $"ca.key" $"($name).vpn"
  chmod 400 $"($name).vpn"
}

# create nebula vpn keys signed by a previously generated vpn ca
#
# outputs:
#   ./name.vpn.pub
#   ./name.vpn
def "main vpn host" [name: string, ca: string = "ca"] {
  let ip = $env.NEBULA_HOST_IP?
  if ($ip | is-empty) {
    error make {
      msg: "expected ip provided via NEBULA_HOST_IP"
    }
  }

  nebula-cert sign -ca-crt $"($ca).vpn.pub" -ca-key $"($ca).vpn" -name $name -ip $ip  

  mv $"($name).crt" $"($name).vpn.pub"
  chmod 644 $"($name).vpn.pub"

  mv $"($name).key" $"($name).vpn"
  chmod 400 $"($name).vpn"
}

# create nebula lighthouse domain config
#
# expects the ip to be in the NEBULA_LIGHTHOUSE_IP env var
# expects the domain to be in the NEBULA_LIGHTHOUSE_DOMAIN env var
#
# outputs:
#   ./name.lighthouse
def "main vpn lighthouse" [name: string, lighthouse: bool] {
  let ip = $env.NEBULA_LIGHTHOUSE_IP?
  if ($ip | is-empty) {
    error make {
      msg: "expected ip provided via NEBULA_LIGHTHOUSE_IP"
    }
  }
  let domain = $env.NEBULA_LIGHTHOUSE_DOMAIN?
  if ($domain | is-empty) {
    error make {
      msg: "expected domain provided via NEBULA_LIGHTHOUSE_DOMAIN"
    }
  }

  let config = (("static_host_map:"
    + $"\n  \"($ip)\": [\"($domain):4242\"]"
    + "\nlighthouse:"
    + $"\n  am_lighthouse: ($lighthouse)")
    + (if $lighthouse { "" } else {
      ("\n  hosts:"
      + $"\n    - '($ip)'") }))
  $config | save -f $"($name).lighthouse"
  chmod 400 $"($name).lighthouse"
}


# create an ssh key pair
#
# outputs:
#   ./name.ssh.pub
#   ./name.ssh
def "main ssh" [name: string] {
  ssh-keygen -q -a 100 -t ed25519 -N $name -f $"($name).ssh"
  chmod 644 $"($name).ssh.pub"
  chmod 400 $"($name).ssh"
}

# create a linux user password using mkpasswd
#
# outputs:
#   ./name.pass.pub
#   ./name.pass
def "main pass" [name: string, length: int = 32] {
  let pass = random chars --length $length
  $pass | save -f $"($name).pass"
  chmod 644 $"($name).pass"

  let encrypted = $pass | mkpasswd --stdin
  $encrypted | save -f $"($name).pass.pub"
  chmod 400 $"($name).pass.pub"
}

# create a random alphanumeric key 
#
# outputs:
#   ./name.key
def "main key" [name: string, length: int = 32] {
  let key = random chars --length $length
  $key | save -f $"($name).key"
  chmod 400 $"($name).key"
}

# create a ddns-updater settings file for duckdns
#
# expects the token to be in the DDNS_UPDATER_DUCKDNS_TOKEN env var
# expects the domain to be in the DDNS_UPDATER_DUCKDNS_DOMAIN env var
#
# outputs:
#   ./name.ddns
def "main ddns" [name: string] {
  let token = $env.DDNS_UPDATER_DUCKDNS_TOKEN?
  if ($token | is-empty) {
    error make {
      msg: "expected token provided via DDNS_UPDATER_DUCKDNS_TOKEN"
    }
  }
  let domain = $env.DDNS_UPDATER_DUCKDNS_DOMAIN?
  if ($domain | is-empty) {
    error make {
      msg: "expected domain provided via DDNS_UPDATER_DUCKDNS_DOMAIN"
    }
  }

  [
    {
      "provider": "duckdns",
      "domain": $"($domain).duckdns.org",
      "token": $token,
      "ip_version": "ipv4"
    }
  ] | to json | save -f $"($name).ddns"
  chmod 400 $"($name).ddns"
}

# create a sops secret file from a directory of secret files and encrypt it
#
# each file in the directory starting with prefix `name` or shared
# will be a secret in the resulting file
# with the name equal to the name of the file
#
# use `sops encrypt --help` to check out available private key options
#
# additionally creates an age key pair
# to be used for decryption during host activation
#
# outputs:
#   ./name.age.pub
#   ./name.age
#   ./name.sops.pub
#   ./name.sops
def "main sops" [name: string] {
  age-keygen | save -f $"($name).age"
  chmod 400 $"($name).age"

  open --raw $"($name).age" | age-keygen -y | save -f $"($name).age.pub"
  chmod 644 $"($name).age.pub"

  ls $env.PWD
    | where { |x| $x.type == "file" }
    | where { |x| 
        let basename = $x.name | path basename
        return (($basename | str starts-with $name) or ($basename | str starts-with shared))
      }
    | each { |x|
        let content = open --raw $x.name
          | str trim
          | str replace --all "\n" "\n  "
        return $"($x.name | path basename): |\n  ($content)" 
      }
    | str join "\n"
    | save -f $"($name).sops"
  chmod 644 $"($name).sops"

  (sops encrypt $"($name).sops"
    --input-type yaml
    --age (open --raw $"($name).age.pub")
    --output $"($name).sops.pub"
    --output-type yaml)
  chmod 400 $"($name).sops.pub"
}
