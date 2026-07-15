def "main menu" [title: string text: string]: list -> string {
  let choices = $in
  log "menu" $"choosing:\n($choices | str join "\n")"
  let result = (
    $choices
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
  zenity --error --title="Toolbelt" $"--text=($text)"
}

def "main choose" [title: string text: string]: list -> string {
  let choices = $in
  log "choose" $"choosing:\n($choices | str join "\n")"
  let result = (
    $choices
      | str join "\n"
      | zenity
          --list
          $"--title=($title)"
          $"--text=($text)"
          --column=Name
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

  let unit = $"zenity-(random uuid)"
  (systemd-run --user --scope $"--unit=($unit)"
    zenity --progress --pulsating --auto-close $"--text=($title)")
  log "wait" $"zenity ($unit) started"

  let result = sh -c $command | complete
  log "wait" $"'($command)' ended with ($result.exit_code)"

  do -i { systemctl stop --user $"($unit).scope" }
  log "wait" $"zenity ($unit) stopped"

  return $result
}

