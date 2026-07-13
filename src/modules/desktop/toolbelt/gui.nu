def "main ui log" [area: string msg: string] {
  let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S")
  let script = ($env.DOT_TOOLBELT_SCRIPT? | default "unknown")
  print -e $"[($timestamp)] [($script)/gui] [($area)]: ($msg)"
}

def "main ui error" []: string -> nothing {
  zenity --error --title="Toolbelt" $"--text=($in)"
}

def "main ui choose" [title: string text: string]: string -> string {
  let result = (
    $in
      | zenity
          --list
          $"--title=($title)"
          $"--text=($text)"
          --column=Name
      | complete
  )
  if $result.exit_code != 0 or ($result.stdout | is-empty) {
    return null
  }

  return $result.stdout | str trim
}

def "main ui wait" [title: string]: string -> nothing {
  let command = $in
  ([ 100 ]
    | each { do -i { sh -c $command }; echo $in }
    | zenity --progress --pulsating --auto-close $"--text=($title)"
    e+o>| ignore)
}

