def "main menu" [title: string text: string]: list -> string {
  let choices = $in
  log "menu" $"choosing:\n($choices | str join "\n")"

  let result = (
    $in
      | str join "\n"
      | ^$env.DOT_TOOLBELT_DMENU -p $text
      | complete
  )
  if $result.exit_code != 0 or ($result.stdout | is-empty) {
    log "menu" "nothing picked"
    return null
  }

  let result = $result.stdout | str trim
  log "menu" $"picked: '($result)'"
  return $result
}

def "main error" []: string -> nothing {
  let text = $in
  log "error" $text

  print -e $in
}

def "main choose" [title: string text: string]: list -> string {
  let choices = $in
  log "choose" $"choosing:\n($choices | str join "\n")"

  let result = (
    $in
      | str join "\n"
      | gum choose
          --limit=1
          --header $title
          --placeholder $text
      | complete
  )
  if $result.exit_code != 0 or ($result.stdout | is-empty) {
    log "choose" "nothing picked"
    return null
  }

  let result = $result.stdout | str trim
  log "choose" $"picked: ($result)"
  return $result
}

def "main wait" [title: string]: string -> record {
  let command = $in
  log "wait" $"running ($title) '($command)'"

  let result = (gum spin
    --title $title
    -- nu -c $"sh -c r#'($command)'# | complete | to json")
    | from json
  log "wait" $"($title) '($command)' ended with ($result.exit_code)"
  return $result
}
