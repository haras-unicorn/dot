def "common handle" [name: string --on-fail: closure]: record -> nothing {
  let result = $in

  if $result.exit_code != 0 {
    [
      $"Command exited with exit code ($result.exit_code)."
      $"Stdout:\n($result.stdout)\n"
      $"Stderr:\n($result.stderr)\n"
    ] | str join "\n" | ui error

    do $on_fail
    exit 1
  }
}
