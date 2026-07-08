def "common handle" [name: string --on-fail: closure]: record -> string {
  let result = $in

  if $result.exit_code != 0 {
    [
      $"Command '($name)' exited with exit code ($result.exit_code)."
      $"Stdout:\n($result.stdout)\n"
      $"Stderr:\n($result.stderr)\n"
    ] | str join "\n" | ui error

    if $on_fail != null {
      do $on_fail
    }
    exit 1
  }

  log "exec" $"command '($name)' exited with exit code 0"

  return $result.stdout
}

def "common err" [name: string command: closure --on-fail: closure]: nothing -> any {
  let result = (try {
    do $command
  } catch { |err|
    [
      $"Command '($name)' exited unsuccessfully."
      $"Error:\n($err)\n"
    ] | str join "\n" | ui error

    if $on_fail != null {
      do $on_fail
    }
    exit 1
  })

  return $result
}

def "common dmenu" [title: string text: string]: list -> string {
  common menu { ^$env.DOT_TOOLBELT_DMENU -p $title }
}

def "common kando" [title: string text: string]: list -> string {
  common menu { ^$env.DOT_TOOLBELT_KANDO }
}

def "common menu" [command: closure]: list -> string {
  let choices = $in
  log "menu" $"choosing:\n($choices | str join "\n")"

  let result = (
    $choices
      | str join "\n"
      | do $command
      | complete
  )

  if $result.exit_code != 0 or ($result.stdout | is-empty) {
    [
      $"Nothing picked and exited with exit code ($result.exit_code)."
      $"Stdout:\n($result.stdout)\n"
      $"Stderr:\n($result.stderr)\n"
    ] | str join "\n" | ui error

    return null
  }

  let result = $result.stdout | str trim
  log "menu" $"picked: '($result)'"
  return $result
}
