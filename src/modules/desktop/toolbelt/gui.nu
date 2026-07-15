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
  zenity --error --title="Toolbelt" $"--text=($text)"
}

def "main choose" [title: string text: string]: string -> string {
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

def "main wait" [title: string]: string -> record {
  let command = $in
  let unit = $"zenity-(random uuid)"
  (systemd-run --user --scope $"--unit=($unit)"
    zenity --progress --pulsating --auto-close $"--text=($title)")

  let result = sh -c $command | complete

  systemctl stop --user $"($unit).scope"

  $result
}

