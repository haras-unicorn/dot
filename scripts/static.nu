let schema = {
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
  }
}

def "to paths" [when: closure] {
  $in
    | transpose path value
    | each { |x|
        if ((($x.value | describe) =~ "record|table") and (do $when $x.value)) {
          $x.value
            | to paths $when
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

def "apply schema paths" [paths: table] {
  $paths
    | reduce --fold $in { |it, acc|
        let default = $it.default?
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

def "apply static paths" [paths: table] {
  $paths
    | reduce --fold $in { |it, acc|
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

export def "static hosts" [] {
  let schema = $schema | to paths { |x| $x.type? != null }

  let hosts = [ ($env.FILE_PWD | path dirname) "src" "host" ] | path join
  let shared_static_path = [ $hosts "static.json" ] | path join
  let shared_static = open if exists $shared_static_path

  ls $hosts
    | each { |x|
        let host = $x.name | path basename
        let static_path = [ $x.name "static.json" ] | path join
        let static = open if exists $static_path
        let result = $shared_static
          | apply static paths ($static | to paths { |_| true })
          | apply schema paths $schema
        {
          host: $host,
          static: $static
        }
      }
    | reduce { |it, acc| $acc | insert $it.host $it.static }
}
