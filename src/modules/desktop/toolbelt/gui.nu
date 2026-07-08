def "ui error" []: string -> nothing {
  zenity --error --title="Toolbelt" $"--text=($in)"
}

def "ui choose" [title: string text: string]: string -> string {
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

def "ui wait" [title: string]: string -> nothing {
  let command = $in
  ([ 100 ]
    | each { do -i { sh -c $command }; echo $in }
    | zenity --progress --pulsating --auto-close $"--text=($title)"
    e+o>| ignore)
}

