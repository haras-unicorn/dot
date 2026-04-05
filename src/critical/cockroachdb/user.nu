def --wrapped "main cockroachdb user" [...args: string] {
  let tmp = (mktemp -d)
  chmod 700 $tmp

  let host = dot host current
  if ($env.DOT_COCKROACHDB_USER_ENV_PATH | path exists) {
    # NOTE: replace home so when running as another user the location is correct
    let env_path = $env.DOT_COCKROACHDB_USER_ENV_PATH | str replace "~" $host.home
    # NOTE: env files are technically a subset of toml
    if ($env.USER != $host.user) {
      sudo cat $env_path | from toml | load-env
    } else {
      open --raw $env_path | from toml | load-env
    }
  } else {
    let shared = dot secrets shared
    let ca_path = [$tmp "ca.crt"] | path join
    let private_path = [$tmp "client.user.key"] | path join
    let public_path = [$tmp "client.user.crt"] | path join
    touch $ca_path
    touch $private_path
    touch $public_path
    chmod 600 $ca_path
    chmod 600 $private_path
    chmod 600 $public_path
    $shared.cockroach-ca-public | save -a $ca_path
    $shared | get $"cockroach-($host.user)-private" | save -a $private_path
    $shared | get $"cockroach-($host.user)-public" | save -a $public_path

    let db_host = dot host first { $in.database? != null }
    let address = $db_host.database.host
    let port = $db_host.database.port
    let pass = $shared | get $"cockroach-($host.user)-pass"

    let url = ($"postgresql://"
      + $"($host.user):($pass)"
      + $"@($address):($port)"
      + "?sslmode=verify-full"
      + $"&sslusercert=($ca_path)"
      + $"&sslcert=($public_path)"
      + $"&sslkey=($private_path)")

    {
      COCKROACH_URL: $url
      PGUSER: $host.user
      PGPASSWORD: $pass
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
