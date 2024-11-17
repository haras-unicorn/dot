#!/usr/bin/env nu

# create secrets for all hosts and lock them
def "main" [] {
  main create
  main lock
}

# create secrets for all hosts
def "main create" [] {
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

  main ssh key shared

  main db ca shared
  main db svc vault
  main db user root
  main db user haras

  main scrt key shared
}

# create secrets for a coordinator host
def "main host coordinator" [
  --name: string, # name of the host
] {
  main ddns $name

  main vpn key $name shared
  main vpn cnf $name --coordinator

  main ssh key $name

  main db key $name shared
  main db sql $name
  main db cnf $name --coordinator

  main pass $name

  main geo $name
}

# create secrets for a regular host
def "main host regular" [
  --name: string, # name of the host
  --ip: string, # ip of the host in the nebula vpn
] {
  main vpn key $name shared
  main vpn cnf $name

  main ssh key $name

  main db key $name shared
  main db cnf $name

  main pass $name

  main geo $name
}

# lock secrets for a host
def "main host lock" [
  --name: string, # name of the host
] {
  main ssh auth $name

  main scrt key $name
  main scrt val $name
}

# create a secret key
#
# assumes sops is used
#
# outputs:
#   ./name.scrt.key.pub
#   ./name.scrt.key
def "main scrt key" [name: string] {
  age-keygen | save -f $"($name).scrt.key"
  chmod 400 $"($name).scrt.key"

  open --raw $"($name).scrt.key" | age-keygen -y | save -f $"($name).scrt.key.pub"
  chmod 644 $"($name).scrt.key.pub"
}

# create secret values
#
# each file in the directory starting with prefix `name` or shared
# excluding secret keys or values
# will be a secret in the resulting file
#
# each file in the directory starting with prefix `name` or shared
# and ending with .key
# will be used to encrypt the resulting file
#
# assumes sops is used
#
# outputs:
#   ./name.scrt.val.pub
#   ./name.scrt.val
def "main scrt val" [name: string] {
  ls $env.PWD
    | where { |x| $x.type == "file" }
    | where { |x| 
        let basename = $x.name | path basename
        return (
          not ($basename | str ends-with ".scrt.val")
          and not ($basename | str ends-with ".scrt.val.pub")
          and not ($basename | str ends-with ".scrt.key")
          and not ($basename | str ends-with ".scrt.key.pub")
          and (
            ($basename | str starts-with $name)
            or ($basename | str starts-with shared)
          )
        )
      }
    | each { |x|
        let content = open --raw $x.name
          | str trim
          | str replace --all "\n" "\n  "
        return $"($x.name | path basename): |\n  ($content)" 
      }
    | str join "\n"
    | save -f $"($name).scrt.val"
  chmod 400 $"($name).scrt.val"

  let keys = ls $env.PWD
    | where { |x| $x.type == "file" }
    | where { |x| 
        let basename = $x.name | path basename
        return (
          ($basename | str ends-with ".scrt.key.pub")
          and (
            ($basename | str starts-with $name)
            or ($basename | str starts-with shared)
          )
        )
      }
    | each { |x| open --raw $x.name }
    | str join ","

  (sops encrypt $"($name).scrt.val"
    --input-type yaml
    --age $keys
    --output $"($name).scrt.val.pub"
    --output-type yaml)
  chmod 644 $"($name).scrt.val.pub"
}

# create the nebula vpn ca
#
# outputs:
#   ./name.vpn.ca.pub
#   ./name.vpn.ca
def "main vpn ca" [name: string = "ca"] {
  nebula-cert ca -name $name -duration $"(365 * 24 * 100)h"

  mv $"ca.crt" $"($name).vpn.ca.pub"
  chmod 644 $"($name).vpn.ca.pub"

  mv $"ca.key" $"($name).vpn.ca"
  chmod 400 $"($name).vpn.ca"
}

# create nebula vpn keys signed by a previously generated vpn ca
#
# additionally saves the ip to a file
#
# expects the ip to be in the VPN_`NAME`_IP env var
#
# assumes nebula vpn is used
#
# outputs:
#   ./name.vpn.key.pub
#   ./name.vpn.key
#   ./name.vpn.ip
def "main vpn key" [name: string, ca: path] {
  let ip_key = $"VPN_($name | str upcase)_IP"
  let ip = $env | default null $ip_key | get $ip_key
  if ($ip | is-empty) {
    error make {
      msg: "expected ip provided via VPN_`NAME`_IP"
    }
  }

  nebula-cert sign -ca-crt $"($ca).vpn.pub" -ca-key $"($ca).vpn" -name $name -ip $ip  

  mv $"($name).crt" $"($name).vpn.key.pub"
  chmod 644 $"($name).vpn.key.pub"

  mv $"($name).key" $"($name).vpn.key"
  chmod 400 $"($name).vpn.key"

  $ip | save -f $"($name).vpn.ip"
  chmod 400 $"($name).vpn.ip"
}

# create nebula vpn config
#
# expects the ip to be in the VPN_COORDINATOR_IP env var
# expects the domain to be in the VPN_COORDINATOR_DOMAIN env var
#
# assumes nebula vpn is used
#
# outputs:
#   ./name.vpn.cnf
def "main vpn cnf" [name: string, --coordinator] {
  let ip = $env.VPN_COORDINATOR_IP?
  if ($ip | is-empty) {
    error make {
      msg: "expected ip provided via VPN_COORDINATOR_IP"
    }
  }
  let domain = $env.VPN_COORDINATOR_DOMAIN?
  if ($domain | is-empty) {
    error make {
      msg: "expected domain provided via VPN_COORDINATOR_DOMAIN"
    }
  }

  (("static_host_map:"
    + $"\n  \"($ip)\": [\"($domain):4242\"]"
    + "\nlighthouse:"
    + $"\n  am_lighthouse: ($coordinator)")
    + (if $coordinator { "" } else {
      ("\n  hosts:"
      + $"\n    - '($ip)'") }))
    | save -f $"($name).vpn.cnf"
  chmod 400 $"($name).vpn.cnf"
}

# create an ssh key pair
#
# assumes that openssh is used
#
# outputs:
#   ./name.ssh.key.pub
#   ./name.ssh.key
def "main ssh key" [name: string] {
  ssh-keygen -q -a 100 -t ed25519 -N "" -C $name -f $"($name).ssh.key"
  chmod 644 $"($name).ssh.key.pub"
  chmod 400 $"($name).ssh.key"
}

# create an ssh authorized_keys file
#
# each file ending with .ssh.pub not starting with `name`
# will be inserted into the final file
#
# assumes that openssh is used
#
# outputs:
#   ./name.ssh.auth.pub
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
    | save -f $"($name).ssh.auth.pub"
  chmod 644 $"($name).ssh.auth.pub"
}

# create the database ssl ca
#
# assumes that database uses openssl kesy
#
# outputs:
#   ./name.db.ca.pub
#   ./name.db.ca
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
# assumes that database uses openssl kesy
#
# outputs:
#   ./name.db.key.pub
#   ./name.db.key
def "main db key" [name: string, ca: path] {
  (openssl genpkey -algorithm ED25519
    -out $"($name).db.key")
  chmod 400 $"($name).db.key"

  (openssl req -new
    -key $"($name).db.key"
    -out $"($name).db.key.req"
    -subj $"/CN=($name)")
  (openssl x509 -req
    -in $"($name).db.key.req"
    -CA $"($ca).db.key.pub"
    -CAkey $"($ca).db.key"
    -CAcreateserial
    -out $"($name).db.key.pub"
    -days 3650)
  rm -f $"($name).db.key.req"
  chmod 644 $"($name).db.key.pub"
}

# create database configuration
#
# expects the cluster ip in the DATABASE_CLUSTER_IP env var
# expects the host ip in the DATABASE_HOST_IP env var
#
# assumes that a mariadb galera cluster is used
#
# outputs:
#   ./name.db.cnf
def "main db cnf" [name: string, --coordinator] {
  let cluster_ip = $env.DATABASE_CLUSTER_IP?
  if ($cluster_ip | is-empty) {
    error make {
      msg: "expected cluster ip provided via DATABASE_CLUSTER_IP"
    }
  }

  let host_ip = $env.DATABASE_HOST_IP?
  if ($host_ip | is-empty) {
    error make {
      msg: "expected host ip provided via DATABASE_HOST_IP"
    }
  }

  $"
    [mysqld]
    wsrep_cluster_address=\"gcomm://($cluster_ip)\"
    wsrep_cluster_name=\"cluster\"
    wsrep_node_address=\"($host_ip)\"
    wsrep_node_name=\"($name)\"
    wsrep_provider_options=\"pc.weight=(if $coordinator { 100 } else { 1 })\"
  " | save -f $"($name).db.cnf"
  chmod 400 $"($name).db.cnf"
}

# create initial database sql script
#
# each file ending with .db.user
# will be included as a corresponding user
# in the database server
#
# each file ending with .db.svc
# will be included as a corresponding service user and database
# in the database server
#
# assumes that a mariadb galera cluster is used
#
# outputs:
#   ./name.db.sql 
def "main db sql" [name: string] {
  let users = ls $env.FILE_PWD
    | where { |x| 
        let basename = $x.name | path basename
        ($x.type == "file") and ($basename | str ends-with ".db.user")
      }
    | each { |x|
        let basename = $x.name | path basename
        let name = $basename | parse "{name}.db.user" | get name
        let pass = open --raw $x.name
        if ($name == "root") {
          $"
            ALTER USER 'root'@'localhost' IDENTIFIED BY '($pass)';
          "
        } else {
          $"
            CREATE USER IF NOT EXISTS '($name)'@'%';
            ALTER USER '($name)'@'%' IDENTIFIED BY '($pass)';
            GRANT ALL PRIVILEGES ON *.* TO '($name)'@'%';
          "
        }
      }
    | str join "\n"

  let services = ls $env.FILE_PWD
    | where { |x| 
        let basename = $x.name | path basename
        ($x.type == "file") and ($basename | str ends-with ".db.svc")
      }
    | each { |x|
        let basename = $x.name | path basename
        let name = $basename | parse "{name}.db.svc" | get name
        let pass = open --raw $x.name
        $"
          CREATE DATABASE IF NOT EXISTS ($name);
          CREATE USER IF NOT EXISTS '($name)'@'%' IDENTIFIED BY '($pass)';
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

    ($users)

    ($services)

    FLUSH PRIVILEGES;
  "

  $sql | save -f $"($name).db.sql"
  chmod 400 $"($name).db.sql"
}

# create a database user password 
#
# outputs:
#   ./name.db.user
def "main db user" [name: string] {
  let key = random chars --length 32
  $key | save -f $"($name).db.user"
  chmod 400 $"($name).db.user"
}

# create a database service password 
#
# outputs:
#   ./name.db.svc
def "main db svc" [name: string] {
  let key = random chars --length 32
  $key | save -f $"($name).db.svc"
  chmod 400 $"($name).db.svc"
}

# create a linux user password
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

# create ddns settings
#
# expects the token to be in the DDNS_DUCKDNS_TOKEN env var
# expects the domain to be in the DDNS_DUCKDNS_DOMAIN env var
#
# assumes that ddns-updater with duckdns provider is used
#
# outputs:
#   ./name.ddns
def "main ddns" [name: string] {
  let token = $env.DDNS_DUCKDNS_TOKEN?
  if ($token | is-empty) {
    error make {
      msg: "expected token provided via DDNS_UPDATER_DUCKDNS_TOKEN"
    }
  }
  let domain = $env.DDNS_DUCKDNS_DOMAIN?
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

# create geolocation settings
#
# expects the api key to be in the GEO_API_KEY env var
#
# assumes that geoclue with google geolocation api is used
#
# outputs:
#   ./name.geo
def "main geo" [name: string] {
  let key = $env.GEOCLUE2_GOOGLE_MAPS_API_KEY?
  if ($key | is-empty) {
    error make {
      msg: "expected api key provided via GEO_API_KEY"
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
