$env.config = {
  show_banner: false

  edit_mode: vi
  cursor_shape: {
    vi_insert: line
    vi_normal: underscore
  }

  table: {
    mode: with_love
  }
}

def "to temp" [] {
  let it = $in
  let file = mktemp -t
  $it | save -f $file
  $file
}
