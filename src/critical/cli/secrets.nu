def "dot secrets hosts" [] {
  $in | each { |host|
    if ($env.DOT_SECRETS_HOSTS? | is-empty) {
      let key = $"kv/dot/host/($host.name)/current"
      let secrets = vault kv get -format=json $key
        | from json
        | get data.data
      $host | insert secrets $secrets
    } else {
      let secrets = ls ([ $env.DOT_SECRETS_HOSTS $in.name ] | path join)
        | each { { key: (basename $in.name), value: (open --raw $in.name) } }
        | transpose -dr
      $host | insert secrets $secrets
    }
  }
}

def "dot secrets shared" [] {
  if ($env.DOT_SECRETS_SHARED? | is-empty) {
    vault kv get -format=json $"($env.DOT_VAULT_SHARED)/current"
      | from json
      | get data.data
  } else {
    ls $env.DOT_SECRETS_SHARED
      | each { { key: (basename $in.name), value: (open --raw $in.name) } }
      | transpose -dr
  }
}
