def "log" [area: string msg: string] {
  print -e here
  let timestamp = (date now | format date %+)
  let script = ($env.DOT_TOOLBELT_SCRIPT? | default "unknown")
  for line in ($msg | lines) {
    print -e $"[($timestamp)] [($script)/tui] [($area)]: ($line)"
  }
}

