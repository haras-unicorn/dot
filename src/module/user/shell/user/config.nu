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

def "to pipe" [] {
  let it = $in
  let file = mktemp -t
  $it | save -f $file
  $file
}

def "to paths" [] {
  $in
    | transpose path value
    | each { |x|
        if (($x.value | describe) =~ "record"
          and (($x.value | get path --ignore-errors) | is-empty)) {
          $x.value
            | to paths
            | each { |y|
                {
                  path: $"($x.path).($y.path)",
                  value: $y.value
                }
              }
        } else {
          [
            {
              path: $x.path
              value: $x.value
            }
          ]
        }
      }
    | flatten
}
