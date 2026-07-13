def "main ui log" [area: string msg: string] {
  let timestamp = (date now | format date %+)
  let script = ($env.DOT_TOOLBELT_SCRIPT? | default "unknown")
  print -e $"[($timestamp)] [($script)/tui] [($area)]: ($msg)"
}

def "main ui error" []: string -> nothing {
  print -e $in
}

def "main ui choose" [title: string text: string]: string -> string {
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

def "main ui wait" [title: string]: string -> nothing {
  do -i {
    (gum spin
      --title $title
      -- sh -c $in)
  }
}
