def --wrapped "main ssh shell" [--host: string, ...args: string] {
  let args = $args | each { $"'($in)'" } | str join " "

  let host = dot host pick --with-secrets $host

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && ssh -t ($args) ($host.user)@($host.ip) motd-wrap nu"
}

def --wrapped "main ssh command" [--host: string, command: string, ...args: string] {
  let args = $args | each { $"'($in)'" } | str join " "

  let host = dot host pick --with-secrets $host

  ssh-agent bash -c $"echo '($host.secrets."ssh-private")' \\
    | ssh-add - \\
    && ssh ($host.user)@($host.ip) '($command)' ($args)"
}

def --wrapped "main ssh copy" [from: string, to: string, ...args: string] {
  let args = $args | each { $"'($in)'" } | str join " "

  let from_split = $from | split row -n 2 ":"
  let to_split = $to | split row -n 2 ":"

  let from_host = if ($from_split | length) == 2 {
    dot host pick --with-secrets $from_split.0
  } else {
    null
  }
  let to_host = if ($to_split | length) == 2 {
    dot host pick --with-secrets $to_split.0
  } else {
    null
  }

  let keys = ""
  let keys = if $from_host != null {
    $"($keys) echo '($from_host.secrets."ssh-private")' | ssh-add - &&"
  } else {
    $keys
  }
  let keys = if $to_host != null {
    $"($keys) echo '($to_host.secrets."ssh-private")' | ssh-add - &&"
  } else {
    $keys
  }

  let source = if $from_host != null {
    $"($from_host.user)@($from_host.ip):($from_split.1)"
  } else {
    $from
  }
  let destination = if $to_host != null {
    $"($from_host.user)@($to_host.ip):($to_split.1)"
  } else {
    $to
  }

  ssh-agent bash -c $"($keys) scp ($args) ($source) ($destination)"
}
