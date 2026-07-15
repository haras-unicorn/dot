def "ui menu" [title: string text: string]: list -> string {
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

def "ui error" []: string -> nothing {
  let text = $in
  log "error" $text

  zenity --error --title="Toolbelt" $"--text=($text)"
}

def "ui choose" [title: string text: string]: list -> string {
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

def "ui wait" [title: string]: string -> record {
  let command = $in
  log "wait" $"running ($title) '($command)'"

  let unit = $"zenity-(random uuid)"
  sh -c (
    $"systemd-run --user --scope '--unit=($unit)'"
    + $" zenity --progress --pulsate --no-cancel --auto-close '--text=($title)'"
    + " &>/dev/null & disown %-"
  )
    | complete
    | common handle "systemd zenity"
  while (systemctl status --user $"($unit).scope"
    | complete
    | get exit_code) != 0 {
    sleep 200ms
  }
  log "wait" $"($title) zenity ($unit) started"

  let result = sh -c $command | complete
  log "wait" $"($title) '($command)' ended with ($result.exit_code)"

  while (systemctl status --user $"($unit).scope"
    | complete
    | get exit_code) == 0 {
    systemctl kill --user --signal SIGINT $"($unit).scope"
  }
  log "wait" $"($title) zenity ($unit) stopped"

  return $result
}

