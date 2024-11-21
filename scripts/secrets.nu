#!/usr/bin/env nu

use std

# create secrets for all hosts and lock them
def "main" []: nothing -> nothing {
  main create
  main lock
}

# create secrets for all hosts
def "main create" []: nothing -> nothing {
  main vpn ca shared

  main ssh key shared

  main ddb ca shared
  main ddb user root
  main ddb user mysql
  main ddb user sst
  main ddb user haras

  main ddb svc vault
  main vault shared

  main scrt key shared

  let hosts = ls ([ ($env.FILE_PWD | path dirname) "src" "host" ] | path join)
    | each { |x|
        let name = $x.name | path basename
        let scripts_path = [ $x.name "scripts.json" ] | path join
        let scripts = if ($scripts_path | path exists) {
          open $scripts_path
        } else {
          { }
        }
        {
          "name": $name,
          "scripts": $scripts
        }
      }

  for $host in $hosts {
    main scrt key $host.name

    if (($host.scripts.ddns? | default null "coordinator") == true) {
      main ddns $host.name
    }

    main vpn key $host.name shared
    if (($host.scripts.vpn? | default null "coordinator") == true) {
      main vpn cnf $host.name --coordinator
    } else {
      main vpn cnf $host.name
    }

    main ssh key $host.name

    main ddb key $host.name shared
    if (($host.scripts.ddb? | default null "coordinator") == true) {
      main ddb sql $host.name
      main ddb cnf $host.name --coordinator
    } else {
      main ddb cnf $host.name
    }

    main nfs $host.name

    main pass $host.name

    main geo $host.name
  }
}

# lock secrets for all hosts
def "main lock" []: nothing -> nothing {
  let hosts = ls ([ ($env.FILE_PWD | path dirname) "src" "host" ] | path join)
    | each { |x| $x.name | path basename }

  for $name in $hosts {
    main ssh auth $name
    main scrt val $name
  }
}

# copy secret values for all hosts
def "main copy vals" []: nothing -> nothing {
  let secrets = ls $env.PWD
    | where { |x| $x.name | str ends-with ".scrt.val.pub" }
    | each { |x| $x.name | path basename }
  let hosts = [ ($env.FILE_PWD | path dirname) "src" "host" ]
    | path join
  for $secret in $secrets {
    let host = $secret | parse "{host}.scrt.val.pub" | get host | first
    let dest = [ $hosts $host "secrets.yaml" ] | path join
    cp -f $secret $dest
  }
}

# copy secret keys for host
#
# if host option is given copies secret key
# to specified remote host
# using ssh and scp
# otherwise, copies the secret key to the current host
def --wrapped "main copy key" [--host: string, ...args]: nothing -> string {
  let this_host = open --raw /etc/hostname
  if (($host | is-empty) or ($host == $this_host)) {
    let host = $this_host
    let origin = [ $env.PWD $"($host).scrt.key" ] | path join
    let dest_dir = [ "/root" ] | path join
    let dest = [ $dest_dir $"host.scrt.key" ] | path join
    sudo mkdir -p $dest_dir
    sudo chown root:root $dest_dir
    sudo chmod 700 $dest_dir
    sudo cp -f $origin $dest
    sudo chown root:root $dest
    sudo chmod 400 $dest
  } else {
    let pass = input -s $"gimme me the password for ($env.USER)@($host) pls\n"
    print "got it! now checking if its alright..."

    def rce [cmd: string]: nothing -> nothing { 
      ssh ...($args) $host $"bash -c 'echo ($pass) | sudo -Sp \"\" ($cmd)'"
    }
    def rcp [origin: string, dest: string]: nothing -> nothing {
      scp ...($args) -q $origin $dest
    }

    mut result = null
    $result = rce "echo test"
    if ($result | is-empty) {
      (print
        $"password for ($env.USER)@($host) is invalid"
        $"or ($env.USER)@($host) is not in wheel group"
        "exiting :(")
      exit 1
    }
    print "the password is fine - thx! :)"

    let name = rce "cat /etc/hostname"
    let backup = $"($name).scrt.key.orig"
    let file = "host.scrt.key"
    let dest_dir = "/root"
    let dest = [ $dest_dir $file ] | path join
    let origin_file = $"($name).scrt.key"
    let origin = [ $env.PWD $origin_file ] | path join
    let tmp_file = $"(random uuid)-($file)"
    let tmp_dest = [ "/home" $env.USER $tmp_file ] | path join

    mut do_backup = false
    try {
      rce $"mv -f ($dest) ($tmp_dest)"
      $do_backup = true
    }
    if $do_backup {
      if ($backup | path exists) {
        (print
          $"backup file ($backup) already exists"
          "can u pls just like move it or delete or sth"
          "thx :)"
          "ill exit now...")
        exit 1
      }
      rce $"chown ($env.USER):(id -gn) ($tmp_dest)"
      rce $"chmod 400 ($tmp_dest)"
      rcp $"($host):($tmp_dest)" $backup
      rce $"rm -f ($tmp_dest)"
    }

    rce $"mkdir -p ($dest_dir)"
    rce $"chown root:root ($dest_dir)"
    rce $"chmod 700 ($dest_dir)"
    rcp $origin $"($host):($tmp_dest)"
    rce $"mv -f ($tmp_dest) ($dest)"
    rce $"chown root:root ($dest)"
    rce $"chmod 400 ($dest)"
  }
}

# create a secret key
#
# assumes sops is used
#
# outputs:
#   ./name.scrt.key.pub
#   ./name.scrt.key
def "main scrt key" [name: string]: nothing -> nothing {
  age-keygen err> (std null-device) out> $"($name).scrt.key"
  chmod 600 $"($name).scrt.key"

  open --raw $"($name).scrt.key"
    | (age-keygen -y
      err> (std null-device)
      out> $"($name).scrt.key.pub")
  chmod 644 $"($name).scrt.key.pub"
}

# create secret values
#
# each file in the directory starting with prefix `name` or shared
# excluding keys or values generated by scrt
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
def "main scrt val" [name: string]: nothing -> nothing {
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
  chmod 600 $"($name).scrt.val"

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
def "main vpn ca" [name: string]: nothing -> nothing {
  nebula-cert ca -name $name -duration $"(365 * 24 * 100)h"

  mv $"ca.crt" $"($name).vpn.ca.pub"
  chmod 644 $"($name).vpn.ca.pub"

  mv $"ca.key" $"($name).vpn.ca"
  chmod 600 $"($name).vpn.ca"
}

# create nebula vpn keys signed by a previously generated vpn ca
#
# expects the ip to be in the VPN_`NAME`_IP env var
#
# assumes nebula vpn is used
#
# outputs:
#   ./name.vpn.key.pub
#   ./name.vpn.key
def "main vpn key" [name: string, ca: path]: nothing -> nothing {
  let ip_key = $"VPN_($name | str upcase)_IP"
  let ip = $env | default null $ip_key | get $ip_key
  if ($ip | is-empty) {
    error make {
      msg: "expected ip provided via VPN_`NAME`_IP"
    }
  }

  (nebula-cert sign
    -ca-crt $"($ca).vpn.ca.pub"
    -ca-key $"($ca).vpn.ca"
    -name $name
    -ip $ip)

  mv $"($name).crt" $"($name).vpn.key.pub"
  chmod 644 $"($name).vpn.key.pub"

  mv $"($name).key" $"($name).vpn.key"
  chmod 600 $"($name).vpn.key"
}

# create nebula vpn config
#
# expects the coordinators to be in the VPN_COORDINATORS env var
# with format ip1=domain1:4242;ip2=domain2:4242;...
#
# assumes nebula vpn is used
#
# outputs:
#   ./name.vpn.cnf
def "main vpn cnf" [name: string, --coordinator]: nothing -> nothing {
  let coordinators = $env.VPN_COORDINATORS?
  if ($coordinators | is-empty) {
    error make {
      msg: "expected coordinators provided via VPN_COORDINATORS"
    }
  }

  let parsed = $coordinators
    | split row ";"
    | split column "=" ip domain
    | where { |x| $x.ip | is-not-empty }

  let static_host_map = $parsed
    | each { |x| $"\n  \"($x.ip)\": [\"($x.domain)\"]" }
    | str join ""

  let am_lighthouse = $"\n  am_lighthouse: ($coordinator)"

  let lighthouse_hosts = if ($coordinator) {
    ""
  } else {
    ("\n  hosts:"
      + ($parsed
        | each { |x| $"\n    - '($x.ip)'" }
        | str join "")) 
  }

  ("static_host_map:"
    + $static_host_map
    + "\nlighthouse:"
    + $am_lighthouse
    + $lighthouse_hosts) | save -f $"($name).vpn.cnf"
  chmod 600 $"($name).vpn.cnf"
}

# create an ssh key pair
#
# assumes that openssh is used
#
# outputs:
#   ./name.ssh.key.pub
#   ./name.ssh.key
def "main ssh key" [name: string]: nothing -> nothing {
  ssh-keygen -q -a 100 -t ed25519 -N "" -C $name -f $"($name).ssh.key"
  chmod 644 $"($name).ssh.key.pub"
  chmod 600 $"($name).ssh.key"
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
def "main ssh auth" [name: string]: nothing -> nothing {
  ls $env.PWD
    | where { |x| $x.type == "file" }
    | where { |x| 
        let basename = $x.name | path basename
        return (
          not ($basename | str starts-with $name)
          and ($basename | str ends-with .ssh.key.pub))
      }
    | each { |x| open --raw $x.name }
    | str join "\n"
    | save -f $"($name).ssh.auth.pub"
  chmod 644 $"($name).ssh.auth.pub"
}

# create the distributed database ssl ca
#
# assumes that the database uses openssl keys
#
# outputs:
#   ./name.ddb.ca.pub
#   ./name.ddb.ca
def "main ddb ca" [name: string]: nothing -> nothing {
  (openssl genpkey -algorithm ED25519
    -out $"($name).ddb.ca")
  chmod 600 $"($name).ddb.ca"

  (openssl req -x509
    -key $"($name).ddb.ca"
    -out $"($name).ddb.ca.pub"
    -subj $"/CN=($name)"
    -days 3650)
  chmod 644 $"($name).ddb.ca.pub"
}

# create distributed database ssl keys
# signed by a previously generated db ca
#
# assumes that the database uses openssl keys
#
# outputs:
#   ./name.ddb.key.pub
#   ./name.ddb.key
def "main ddb key" [name: string, ca: path]: nothing -> nothing {
  (openssl genpkey -algorithm ED25519
    -out $"($name).ddb.key")
  chmod 600 $"($name).ddb.key"

  (openssl req -new
    -key $"($name).ddb.key"
    -out $"($name).ddb.key.req"
    -subj $"/CN=($name)")
  (openssl x509 -req
    -in $"($name).ddb.key.req"
    -CA $"($ca).ddb.ca.pub"
    -CAkey $"($ca).ddb.ca"
    -CAcreateserial
    -out $"($name).ddb.key.pub"
    -days 3650) err>| ignore
  rm -f $"($name).ddb.key.req"
  chmod 644 $"($name).ddb.key.pub"
}

# create distributed database configuration
#
# expects the cluster ip in the DDB_CNF_CLUSTER_IPS env var
# with format ip1,ip2,ip3...
# 
# expects the host ip in the DDB_CNF_`NAME`_IP env var
#
# assumes that a mariadb galera cluster is used
#
# outputs:
#   ./name.ddb.cnf
def "main ddb cnf" [name: string, --coordinator]: nothing -> nothing {
  let cluster_ips = $env.DDB_CNF_CLUSTER_IPS?
  if ($cluster_ips | is-empty) {
    error make {
      msg: "expected cluster ips provided via DDB_CNF_CLUSTER_IPS"
    }
  }
  let cluster_ips = $cluster_ips
    | split row ","
    | where { |x| $x | is-not-empty }
    | str join "," 

  let host_ip_key = $"DDB_CNF_($name | str upcase)_IP"
  let host_ip = $env | default null $host_ip_key | get $host_ip_key
  if ($host_ip | is-empty) {
    error make {
      msg: "expected host ip provided via DDB_CNF_`name`_IP"
    }
  }

  $"[mysqld]
wsrep_cluster_address=\"gcomm://($cluster_ips)\"
wsrep_cluster_name=\"cluster\"
wsrep_node_address=\"($host_ip)\"
wsrep_node_name=\"($name)\"
wsrep_sst_method=\"mariabackup\"
wsrep_sst_auth=\"sst:(open --raw sst.ddb.user)\""
    | save -f $"($name).ddb.cnf"
  chmod 600 $"($name).ddb.cnf"
}

# create initial distributed database sql script
#
# each file ending with .ddb.svc
# will be included as a corresponding service database
# and user with all permissions to that database
# in the database cluster
#
# each file ending with .ddb.user
# will be included as a corresponding user
# with all permissions for all service databases 
# in the database cluster
#
# expects user host names in the DDB_SQL_HOST_NAMES env var
# with format hostname1,hostname2,...
#
# assumes that a mariadb galera cluster is used
#
# outputs:
#   ./name.ddb.sql 
def "main ddb sql" [name: string]: nothing -> nothing {
  let host_names = $env.DDB_SQL_HOST_NAMES?
  if ($host_names | is-empty) {
    error make {
      msg: "expected cluster ips provided via DDB_SQL_HOST_NAMES"
    }
  }
  let host_names = $host_names | split row ","

  let services = ls $env.PWD
    | where { |x| 
        let basename = $x.name | path basename
        ($x.type == "file") and ($basename | str ends-with ".ddb.svc")
      }
    | each { |x|
        let basename = $x.name | path basename
        let name = $basename | parse "{name}.ddb.svc" | get name | first
        let pass = open --raw $x.name
        {
          "name": $name,
          "pass": $pass
        }
      }

  let users = ls $env.PWD
    | where { |x| 
        let basename = $x.name | path basename
        ($x.type == "file") and ($basename | str ends-with ".ddb.user")
      }
    | each { |x|
        let basename = $x.name | path basename
        let name = $basename | parse "{name}.ddb.user" | get name | first
        let pass = open --raw $x.name
        let services = $services
          | each { |service| 
              $host_names
                | each { |host| $"GRANT ALL PRIVILEGES ON ($service.name).* TO '($name)'@'($host)';"  }
                | each { |x| $"\n    ($x)" }
                | str join ""
            }
          | str join ""
        if ($name == "root") {
          $"\n    ALTER USER 'root'@'localhost' IDENTIFIED BY '($pass)';"
        } else if ($name == "mysql") {
          $"\n    ALTER USER 'mysql'@'localhost' IDENTIFIED BY '($pass)';"
        } else if ($name == "sst") {
          ($"\n    CREATE USER IF NOT EXISTS 'sst'@'localhost' IDENTIFIED BY '($pass)';"
            + $"\n    GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, PROCESS, SLAVE MONITOR ON *.* TO 'sst'@'localhost';")
        } else {
          let hosts = $host_names
            | each { |host| $"CREATE USER IF NOT EXISTS '($name)'@'($host)' IDENTIFIED BY '($pass)';" }
            | each { |x| $"\n    ($x)" }
            | str join ""
          $hosts + $services
        }
      }
    | str join "\n"

  let services = $services
    | each { |x|
        let hosts = $host_names
          | each { |host|
              [
                $"CREATE USER IF NOT EXISTS '($x.name)'@'($host)' IDENTIFIED BY '($x.pass)';"
                $"GRANT ALL PRIVILEGES ON ($x.name).* TO '($x.name)'@'($host)';"
              ] | each { |x| $"\n    ($x)" }
                | str join ""
            }
          | str join ""
        ($"\n    CREATE DATABASE IF NOT EXISTS ($x.name);"
          + $hosts)
      }
    | str join "\n"

  let sql = $"CREATE DATABASE IF NOT EXISTS init;
USE init;

DROP PROCEDURE IF EXISTS init;

DELIMITER $$
CREATE PROCEDURE init\(\)
BEGIN
  return_label: BEGIN
    DECLARE already_initialized INT DEFAULT 0;
  
    START TRANSACTION;
  
    CREATE TABLE IF NOT EXISTS init \(
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    \);
  
    SELECT COUNT\(*\) INTO already_initialized FROM init;
  
    IF already_initialized > 0 THEN
      ROLLBACK;
      LEAVE return_label;
    END IF;

    INSERT INTO init \(timestamp\) VALUES
      \(CONVERT_TZ\(CURRENT_TIMESTAMP, '+00:00', '+00:00'\)\)
    ;

    COMMIT;
($services)
($users)

    FLUSH PRIVILEGES;
  END return_label;
END$$
DELIMITER ;

CALL init\(\);"

  $sql | save -f $"($name).ddb.sql"
  chmod 600 $"($name).ddb.sql"
}

# create a distributed database user password 
#
# outputs:
#   ./name.ddb.user
def "main ddb user" [name: string]: nothing -> nothing {
  let key = random chars --length 32
  $key | save -f $"($name).ddb.user"
  chmod 600 $"($name).ddb.user"
}

# create a distributed database service password 
#
# outputs:
#   ./name.ddb.svc
def "main ddb svc" [name: string]: nothing -> nothing {
  let key = random chars --length 32
  $key | save -f $"($name).ddb.svc"
  chmod 600 $"($name).ddb.svc"
}

# create a nfs secrets environemnt file
#
# assumes that a garage cluster is used
#
# outputs:
#   ./name.nfs
def "main nfs" [name: string]: nothing -> nothing {
  $"GARAGE_RPC_SECRET=\"(openssl rand -hex 32)\"
GARAGE_ADMIN_TOKEN=\"(openssl rand -base64 32)\"
GARAGE_METRICS_TOKEN=\"(openssl rand -base64 32)\""
    | save -f $"($name).fs"  
  chmod 600 $"($name).fs"
}

# create vault service settings
#
# outputs:
#   ./name.vault
def "main vault" [name: string]: nothing -> nothing {
  let settings = $"storage \"mysql\" {
  username = \"vault\"
  password = \"(open --raw "vault.ddb.svc")\"
  database = \"vault\"
}"
  $settings | save -f $"($name).vault"
  chmod 600 $"($name).vault"
}

# create a linux user password
#
# outputs:
#   ./name.pass.pub
#   ./name.pass
def "main pass" [name: string, length: int = 32]: nothing -> nothing {
  let pass = random chars --length $length
  $pass | save -f $"($name).pass"
  chmod 644 $"($name).pass"

  let encrypted = $pass | mkpasswd --stdin
  $encrypted | save -f $"($name).pass.pub"
  chmod 600 $"($name).pass.pub"
}

# create ddns settings
#
# expects the token to be in the DDNS_`NAME`_TOKEN env var
#
# expects the domain to be in the DDNS_`NAME`_DOMAIN env var
#
# assumes that ddns-updater with duckdns provider is used
#
# outputs:
#   ./name.ddns
def "main ddns" [name: string]: nothing -> nothing {
  let token_key = $"DDNS_($name | str upcase)_TOKEN"
  let token = $env | default null $token_key | get $token_key
  if ($token | is-empty) {
    error make {
      msg: "expected token provided via DDNS_`NAME`_TOKEN"
    }
  }

  let domain_key = $"DDNS_($name | str upcase)_DOMAIN"
  let domain = $env | default null $domain_key | get $domain_key
  if ($domain | is-empty) {
    error make {
      msg: "expected domain provided via DDNS_`NAME`_DOMAIN"
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
  chmod 600 $"($name).ddns"
}

# create geolocation settings
#
# expects the api key to be in the GEO_`name`_API_KEY env var
#
# assumes that geoclue with google geolocation api is used
#
# outputs:
#   ./name.geo
def "main geo" [name: string]: nothing -> nothing {
  let key_key = $"GEO_($name | str upcase)_API_KEY"
  let key = $env | default null $key_key | get $key_key
  if ($key | is-empty) {
    error make {
      msg: "expected api key provided via GEO_`name`_API_KEY"
    }
  }

  ("[wifi]"
    + "\nurl=https://www.googleapis.com/geolocation/v1/geolocate?key="
    + $key) | save -f $"($name).geo"
  chmod 600 $"($name).geo"
}

# create a random alphanumeric key of specified length
#
# outputs:
#   ./name.key
def "main key" [name: string, length: number = 32]: nothing -> nothing {
  let key = random chars --length $length
  $key | save -f $"($name).key"
  chmod 600 $"($name).key"
}
