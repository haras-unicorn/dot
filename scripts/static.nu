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

export def "static hosts" [] {
  ls ([ ($env.FILE_PWD | path dirname) "src" "host" ] | path join)
    | each { |x|
        def "parse" [x] {
          # ddns.coordinator = val [ "ddns" "coordinator" ];
          # vpn.coordinator = val [ "vpn" "coordinator" ];
          # vpn.ip = val [ "vpn" "ip" ];
          # vpn.subnet.ip = val [ "vpn" "subnet" "ip" ];
          # vpn.subnet.bits = val [ "vpn" "subnet" "bits" ];
          # vpn.subnet.mask = val [ "vpn" "subnet" "mask" ];
          # ddb.coordinator = val [ "ddb" "coordinator" ];
          # nfs.coordinator = val [ "nfs" "coordinator" ];
          # nfs.node = val [ "nfs" "node" ];
        }

        let name = $x.name | path basename
        let scripts_path = [ $x.name "scripts.json" ] | path join
        let value = if ($scripts_path | path exists) {
          open $scripts_path
        } else {
          { }
        }
        {
          "name": $name,
          "value": $value
        }
      }
    | reduce { |x, acc| $acc | insert $x.name $x.scripts }
}
