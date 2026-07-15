def "common handle" [name: string --on-fail: closure]: record -> nothing {
  let result = $in

  if $result.exit_code != 0 {
    log "error" $"($name) command exited with exit code ($result.exit_code)"
    log "error" $"stdout:\n($result.stdout)\n"
    log "error" $"stderr:\n($result.stderr)\n"

    [
      $"Command exited with exit code ($result.exit_code)."
      $"Stdout:\n($result.stdout)\n"
      $"Stderr:\n($result.stderr)\n"
    ] | str join "\n" | ui error

    do $on_fail
    exit 1
  }
}
