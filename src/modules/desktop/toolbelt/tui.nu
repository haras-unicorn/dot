def "ui error" []: string -> nothing {
  print -e $in
}

def "ui choose" [title: string text: string]: string -> string {
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

def "ui wait" [title: string]: string -> nothing {
  do -i {
    (gum spin
      --title $title
      -- sh -c $in)
  }
}
