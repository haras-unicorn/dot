def "main menu" [title: string text: string]: string -> string {
  let result = (
    $in
      | ^$env.DOT_TOOLBELT_DMENU -p $text
      | complete
  )
  if $result.exit_code != 0 or ($result.stdout | is-empty) {
    return null
  }

  return $result.stdout | str trim
}

def "main error" []: string -> nothing {
  let text = $in
  log "error" $text
  print -e $in
}

def "main choose" [title: string text: string]: string -> string {
  let result = (
    $in
      | gum choose
          --limit=1
          --header $title
          --placeholder $text
      | complete
  )
  if $result.exit_code != 0 or ($result.stdout | is-empty) {
    return null
  }

  return $result.stdout | str trim
}

def "main wait" [title: string]: string -> record {
  (gum spin
    --title $title
    -- nu -c $"sh -c r#'($in)'# | complete | to json")
    | from json
}
