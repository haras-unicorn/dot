def "ui error" []: string -> nothing {
  let text = $in
  log "error" $text

  zenity --error --title="Toolbelt" $"--text=($text)"
}

def "ui menu" [title: string text: string]: list -> string {
  common menu {
   (zenity
      --list
      $"--title=($title)"
      $"--text=($text)"
      --column=Name)
  }
}

def "ui wait" [title: string, command: closure, --on-fail: closure]: nothing -> any {
  log "wait" $"running ($title)"

  def "start zenity" []: nothing -> string {
    let unit = $"zenity-(random uuid)"

    sh -c (
      $"systemd-run --user --scope '--unit=($unit)'"
      + (
        " nu -c \"[ 100 ]"
        + " | each { sleep 3600sec; echo $in }"
        + $" | zenity --progress --pulsate --no-cancel --auto-close '--text=($title)'\""
      )
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

    return $unit
  }

  def "stop zenity" []: string -> nothing {
    let unit = $in
    while (systemctl status --user $"($unit).scope"
      | complete
      | get exit_code) == 0 {
      systemctl kill --user --signal SIGINT $"($unit).scope" | complete
      sleep 200ms
    }
    log "wait" $"($title) zenity ($unit) stopped"
  }

  let unit = start zenity
  let result = common err $title $command --on-fail {
    $unit | stop zenity
    if ($on_fail | is-not-empty) { do $on_fail }
  }
  log "wait" $"($title) ended with ($result)"
  $unit | stop zenity

  return $result
}

