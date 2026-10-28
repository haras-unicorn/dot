def "ui error" []: string -> nothing {
  let text = $in
  log "error" $text

  print -e $text
}

def "ui menu" [title: string text: string]: list -> string {
  common menu {
    (gum choose
      --limit=1
      --header $title
      --placeholder $text)
  }
}

def "ui wait" [title: string, command: closure, --on-fail: closure]: nothing -> any {
  log "wait" $"running ($title)"

  def "start gum" []: nothing -> string {
    let unit = $"gum-(random uuid)"
    sh -c (
      $"systemd-run --user --scope '--unit=($unit)'"
      + $"gum spin --title '($title)' -- sleep 3600"
      + " & disown %-"
    )
      | complete
      | common handle "systemd gum"
    while (systemctl status --user $"($unit).scope"
      | complete
      | get exit_code) != 0 {
      sleep 200ms
    }
    log "wait" $"($title) gum ($unit) started"
    return $unit
  }

  def "stop gum" []: string -> nothing {
    let unit = $in
    while (systemctl status --user $"($unit).scope"
      | complete
      | get exit_code) == 0 {
      systemctl kill --user --signal SIGINT $"($unit).scope" | complete
      sleep 200ms
    }
    log "wait" $"($title) gum ($unit) stopped"
  }

  let unit = start gum
  let result = common err $title $command --on-fail {
    $unit | stop gum
    if ($on_fail | is-not-empty) { do $on_fail }
  }
  log "wait" $"($title) ended with ($result)"
  $unit | stop gum

  return $result
}
