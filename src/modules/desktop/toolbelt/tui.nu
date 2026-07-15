def "main log" [area: string msg: string] {
  let timestamp = (date now | format date %+)
  let script = ($env.DOT_TOOLBELT_SCRIPT? | default "unknown")
  print -e $"[($timestamp)] [($script)/tui] [($area)]: ($msg)"
}

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
