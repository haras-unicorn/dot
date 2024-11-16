#!/usr/bin/env nu

let user = "haras"

# create secrets for all hosts
def "main" [] {
  main gen
  main lock
}

# create secrets for all hosts
def "main gen" [] {
  main shared
  main host coordinator --name puffy
  main host regular --name hearth
  main host regular --name workbug
  main host regular --name officer
}

# lock secrets for all hosts
def "main lock" [] {
  main host lock --name puffy
  main host lock --name hearth
  main host lock --name workbug
  main host lock --name officer
}

# create secrets shared between hosts
def "main shared" [] {
  main vpn ca shared
  main db ca shared
  main db service vault
  main key shared-db-root
  main key shared-db-user
}

# create secrets for a coordinator host
def "main host coordinator" [
  --name: string, # name of the host
] {
  main ddns $name
  main vpn host $name shared
  main vpn config $name --lighthouse
  main ssh key $name
  main db host $name shared
  main db sql $name shared-db-root.key shared-db-user.key
  main db config $name --arbitrator
  main pass $name
  main geo $name
}

# create secrets for a regular host
def "main host regular" [
  --name: string, # name of the host
  --ip: string, # ip of the host in the nebula vpn
] {
  main vpn host $name shared
  main vpn config $name
  main ssh key $name
  main db host $name shared
  main db config $name
  main pass $name
  main geo $name
}

# lock secrets for a host
#
# this includes ssh authorized keys files and sops secrets files
def "main host lock" [
  --name: string, # name of the host
] {
  main ssh auth $name
  main sops $name
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
        return (
          not ($basename | str ends-with ".sops")
          and not ($basename | str ends-with ".sops.pub")
          and (($basename | str starts-with $name)
          or ($basename | str starts-with shared)))
      }
    | each { |x|
        let content = open --raw $x.name
          | str trim
          | str replace --all "\n" "\n  "
        return $"($x.name | path basename): |\n  ($content)" 
      }
    | str join "\n"
    | save -f $"($name).sops"
  chmod 400 $"($name).sops"

  (sops encrypt $"($name).sops"
    --input-type yaml
    --age (open --raw $"($name).age.pub")
    --output $"($name).sops.pub"
    --output-type yaml)
  chmod 644 $"($name).sops.pub"
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
# expects the ip to be in the NEBULA_`NAME`_IP env var
#
# outputs:
#   ./name.vpn.pub
#   ./name.vpn
#   ./name.ip
def "main vpn host" [name: string, ca: path = "ca"] {
  let ip_key = $"NEBULA_($name | str upcase)_IP"
  let ip = $env | default null $ip_key | get $ip_key
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

  $ip | save -f $"($name).ip"
  chmod 400 $"($name).ip"
}

# create nebula vpn config
#
# expects the ip to be in the NEBULA_LIGHTHOUSE_IP env var
# expects the domain to be in the NEBULA_LIGHTHOUSE_DOMAIN env var
#
# outputs:
#   ./name.lighthouse
def "main vpn config" [name: string, --lighthouse] {
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
def "main ssh key" [name: string] {
  ssh-keygen -q -a 100 -t ed25519 -N "" -C $name -f $"($name).ssh"
  chmod 644 $"($name).ssh.pub"
  chmod 400 $"($name).ssh"
}

# create an ssh authorized_keys file
#
# each file ending with .ssh.pub not starting with `name`
# will be inserted into the final file
#
# outputs:
#   ./name.auth.pub
def "main ssh auth" [name: string] {
  ls $env.PWD
    | where { |x| $x.type == "file" }
    | where { |x| 
        let basename = $x.name | path basename
        return (
          not ($basename | str starts-with $name)
          and ($basename | str ends-with .ssh.pub))
      }
    | each { |x| open --raw $x.name }
    | str join "\n"
    | save -f $"($name).auth.pub"
  chmod 644 $"($name).auth.pub"
}

# create the database ssl ca
#
# outputs:
#   ./name.db.pub
#   ./name.db
def "main db ca" [name: string] {
  (openssl genpkey -algorithm ED25519
    -out $"($name).db")
  chmod 400 $"($name).db"

  (openssl req -x509
    -key $"($name).db"
    -out $"($name).db.pub"
    -subj $"/CN=($name)"
    -days 3650)
  chmod 644 $"($name).db.pub"
}

# create database ssl keys signed by a previously generated ca
#
# outputs:
#   ./name.db.pub
#   ./name.db
def "main db host" [name: string, ca: path] {
  (openssl genpkey -algorithm ED25519
    -out $"($name).db")
  chmod 400 $"($name).db"

  (openssl req -new
    -key $"($name).db"
    -out $"($name).db.req"
    -subj $"/CN=($name)")
  (openssl x509 -req
    -in $"($name).db.req"
    -CA $"($ca).db.pub"
    -CAkey $"($ca).db"
    -CAcreateserial
    -out $"($name).db.pub"
    -days 3650)
  rm -f $"($name).db.req"
  chmod 644 $"($name).db.pub"
}

# create database configuration
#
# expects the cluster ip in the GALERA_CLUSTER_IP env var
# expects the host ip in the GALERA_HOST_IP env var
#
# outputs:
#   ./name.galera
def "main db config" [name: string, --arbitrator] {
  let cluster_ip = $env.GALERA_CLUSTER_IP?
  if ($cluster_ip | is-empty) {
    error make {
      msg: "expected cluster ip provided via GALERA_CLUSTER_IP"
    }
  }

  let host_ip = $env.GALERA_HOST_IP?
  if ($host_ip | is-empty) {
    error make {
      msg: "expected host ip provided via GALERA_HOST_IP"
    }
  }

  let galera =  $"
    wsrep_cluster_address=\"gcomm://($cluster_ip)\"
    wsrep_cluster_name=\"galera\"
    wsrep_node_address=\"($host_ip)\"
    wsrep_node_name=\"($name)\"
    wsrep_provider_options=\"pc.weight=(if $arbitrator { 10 } else { 1 })\"
  "
  $galera | save -f $"($name).galera"
}

# create initial database sql script
#
# each file ending with .service
# will be included as a corresponding service user and database
# in the database server
#
# outputs:
#   ./name.sql 
def "main db sql" [name: string, rootpass: string, userpass: string] {
  let services = ls $env.FILE_PWD
    | where { |x| 
        let basename = $x.name | path basename
        ($x.type == "file") and ($basename | str ends-with ".service.db.key")
      }
    | each { |x|
        let basename = $x.name | path basename
        let name = $basename | parse "{name}.service" | get name
        let pass = open --raw $x.name
        $"
          CREATE DATABASE IF NOT EXISTS ($name);
          CREATE USER IF NOT EXISTS '($name)'@'%' IDENTIFIED BY '($pass)';
          GRANT ALL PRIVILEGES ON ($name).* TO '($user)'@'%';
          GRANT ALL PRIVILEGES ON ($name).* TO '($name)'@'%';
        "
      }
    | str join "\n"

  let sql = $"
    START TRANSACTION;
    CREATE DATABASE IF NOT EXISTS init;
    USE init;
    CREATE TABLE IF NOT EXISTS init \(
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    \);
    SELECT COUNT\(*\) INTO @already_initialized FROM init;
    DO CASE
      WHEN @already_initialized > 0 THEN
        ROLLBACK;
        LEAVE;
      END CASE;
    INSERT INTO init \(timestamp\) VALUES \(CONVERT_TZ\(CURRENT_TIMESTAMP, '+00:00', '+00:00'\)\);
    COMMIT;

    ALTER USER 'root'@'localhost' IDENTIFIED BY '(open --raw $rootpass)';
    CREATE USER IF NOT EXISTS '($user)'@'%' IDENTIFIED BY '(open --raw $userpass)';

    ($services)

    FLUSH PRIVILEGES;
  "

  $sql | save -f $"($name).sql"
  chmod 400 $"($name).sql"
}

# create a database service password 
#
# outputs:
#   ./name.service
def "main db service" [name: string] {
  let key = random chars --length 32
  $key | save -f $"($name).service"
  chmod 400 $"($name).service"
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

  {
    "settings": [
      {
        "provider": "duckdns",
        "domain": $"($domain).duckdns.org",
        "token": $token,
        "ip_version": "ipv4"
      }
    ]
  } | to json | save -f $"($name).ddns"
  chmod 400 $"($name).ddns"
}

# create geoclue2 provider settings for google maps api
#
# expects the api key to be in the GEOCLUE2_GOOGLE_MAPS_API_KEY env var
#
# outputs:
#   ./name.geo
def "main geo" [name: string] {
  let key = $env.GEOCLUE2_GOOGLE_MAPS_API_KEY?
  if ($key | is-empty) {
    error make {
      msg: "expected api key provided via GEOCLUE2_GOOGLE_MAPS_API_KEY"
    }
  }

  ("[wifi]"
    + "\nurl=https://www.googleapis.com/geolocation/v1/geolocate?key="
    + $key) | save -f $"($name).geo"
  chmod 400 $"($name).geo"
}

# create a random alphanumeric key of specified length
#
# outputs:
#   ./name.key
def "main key" [name: string, length: number = 32] {
  let key = random chars --length $length
  $key | save -f $"($name).key"
  chmod 400 $"($name).key"
}
