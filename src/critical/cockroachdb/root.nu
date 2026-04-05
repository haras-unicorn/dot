def --wrapped "main cockroachdb root" [...args: string] {
  let tmp = (mktemp -d)
  chmod 700 $tmp

  if ($env.DOT_COCKROACHDB_ROOT_ENV_PATH | path exists) {
    # NOTE: env files are technically a subset of toml
    if ($env.USER != "root") {
      sudo cat $env.DOT_COCKROACHDB_ROOT_ENV_PATH | from toml | load-env
    } else {
      open --raw $env.DOT_COCKROACHDB_ROOT_ENV_PATH | from toml | load-env
    }
  } else {
    let shared = dot secrets shared
    let ca_path = [$tmp "ca.crt"] | path join
    let private_path = [$tmp "client.root.key"] | path join
    let public_path = [$tmp "client.root.crt"] | path join
    touch $ca_path
    touch $private_path
    touch $public_path
    chmod 600 $ca_path
    chmod 600 $private_path
    chmod 600 $public_path
    $shared.cockroach-ca-public | save -a $ca_path
    $shared.cockroach-root-private | save -a $private_path
    $shared.cockroach-root-public | save -a $public_path

    let db_host = dot host first { $in.database? != null }
    let address = $db_host.database.host
    let port = $db_host.database.port

    let url = ($"postgresql://root:($shared.cockroach-root-pass)@($address)"
      + $":($port)"
      + "?sslmode=verify-full"
      + $"&sslrootcert=($ca_path)"
      + $"&sslcert=($public_path)"
      + $"&sslkey=($private_path)")

    {
      COCKROACH_URL: $url
      PGUSER: "root"
      PGPASSWORD: $shared.cockroach-root-pass
      PGHOST: $address
      PGPORT: $port
      PGSSLMODE: "verify-full"
      PGSSLROOTCERT: $ca_path
      PGSSLCERT: $public_path
      PGSSLKEY: $private_path
    } | load-env
  }

  let result = cockroachdb ...($args) | complete
  rm -rf $tmp
  print $result.stdout
  print -e $result.stderr
  exit $result.exit_code
}
