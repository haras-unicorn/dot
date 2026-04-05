def "main host pass" [host?: string] {
 dot host pick --with-secrets $host | get secrets."pass-priv"
}

def "dot host current" [--with-secrets] {
  let hosts = dot host all
  let host = $hosts | where name == (hostname) | first

  if not $with_secrets {
    return $host
  }

  [ $host ] | dot secrets hosts | first
}

def "dot host first" [--with-secrets, filter?: closure] {
  let hosts = dot host all
  let host = if $filter != null {
    $hosts | where $filter | first
  } else {
    $hosts | first
  }

  if not $with_secrets {
    return $host
  }

  [ $host ] | dot secrets hosts | first
}

def "dot host pick" [--with-secrets, name?: string] {
  let hosts = dot host all
  mut host = null

  if ($name != null) {
    $host = $hosts | where $it.name == $name | first
  } else {
    let wanted = (gum choose --header "Pick host name:" ...($hosts | get name ))
    $host = $hosts | where $it.name == $wanted | first
  }

  if not $with_secrets {
    return $host
  }

  [ $host ] | dot secrets hosts | first
}

def "dot host all" [--with-secrets] {
  mut hosts = $env.DOT_HOSTS
    | from json

  $hosts = $hosts | each { |host|
    $host | insert configuration $host.name
  }

  if not $with_secrets {
    return $hosts
  }

  $hosts | dot secrets hosts
}
