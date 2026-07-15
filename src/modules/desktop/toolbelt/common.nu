def "common handle" [name: string --on-fail: closure]: record -> nothing {
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

  return $result
}
