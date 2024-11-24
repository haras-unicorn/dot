const schema = {
  "ddns": {
    "coordinator": {
      "type": "bool"
      "default": false
    }
  }
  "vpn": {
    "coordinator": {
      "type": "bool"
      "default": false
    }
    "ip": {
      "type": "string"
    }
    "subnet": {
      "ip": {
        "type": "string"
      }
      "bits": {
        "type": "int"
      }
      "mask": {
        "type": "string"
      }
    }
  }
  "ddb": {
    "coordinator": {
      "type": "bool"
      "default": false
    }
  }
  "nfs": {
    "coordinator": {
      "type": "bool"
      "default": false
    }
    "node": {
      "type": "string"
    }
    "trusted": {
      "type": "bool"
      "default": false
    }
  }
}

def "to paths" [when] {
  def recurse [when, curr = ""] {
    $in
      | transpose path value
      | each { |x|
          if ((($x.value | describe) =~ "record|table") and (do $when $x.value)) {
            $x.value | recurse $when $x.path
          } else {
            [
              {
                path: $"($curr).($x.path)"
                value: $x.value
              }
            ]
          }
        }
      | flatten
  }

  $in
    | recurse $when
    | each { |x|
        {
          path: ($x.path | split row "." | into cell-path)
          value: $x.value
        }
      }
}

def "apply schema paths" [paths] {
  let this_in = $in
  $paths
    | reduce --fold $this_in { |it, acc|
        let default = $it.value.default?
        if ($default | is-not-empty) {
          try {
            $acc | insert $it.path $default 
          } catch {
            $acc
          }
        } else {
          $acc
        }
      }
}

def "apply static paths" [paths] {
  let this_in = $in
  $paths
    | reduce --fold $this_in { |it, acc|
        try {
          $acc | update $it.path $it.value 
        } catch {
          $acc | insert $it.path $it.value 
        }
      }
}

def "open if exists" [path: path] {
  if ($path | path exists) {
    open $path
  } else {
    { }
  }
}

export def "static hosts" [hosts: path] {
  let schema_paths = $schema | to paths { |x| $x.type? == null }

  let shared_static_path = [ $hosts "static.json" ] | path join
  let shared_static = open if exists $shared_static_path

  ls $hosts
    | where $it.type == "dir"
    | each { |x|
        let host = $x.name | path basename
        let static_path = [ $x.name "static.json" ] | path join
        let static = open if exists $static_path
        let result = $shared_static
          | apply static paths ($static | to paths { |_| true })
          | apply schema paths $schema_paths
        {
          name: $host,
          static: $result
        }
      }
    | reduce --fold { } { |it, acc| $acc | insert $it.name $it.static }
}
