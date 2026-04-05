let nebula_base_template = "
firewall:
  inbound:
    - host: any
      port: any
      proto: any
  outbound:
    - host: any
      port: any
      proto: any
listen:
  host: '[::]'
  port: 0
pki:
  ca: \"{{CA_PUBLIC}}\"
  key: \"{{CERT_PRIVATE}}\"
  cert: \"{{CERT_PUBLIC}}\"
handshakes:
  try_interval: 1s
static_map:
  cadence: 5m
  lookup_timeout: 10s
preferred_ranges: [ '192.168.1.0/24' ]
" | str trim

def "main nebula" [ip: string, --host: string] {
  let host = if $host == null {
      open --raw /etc/hostname
    } else {
      $host
    } | str trim

  let shared = vault kv get -format=json "kv/dot/shared/current"
    | from json
    | get data.data

  let artifacts = [ (flake-root) "artifacts" ] | path join
  rm -rf $artifacts
  mkdir $artifacts
  cd $artifacts

  {
    imports: [
      {
        importer: "vault-file"
        arguments: {
          path: "kv/dot/shared"
          file: "nebula-ca-private"
        }
      }
      {
        importer: "vault-file"
        arguments: {
          path: "kv/dot/shared"
          file: "nebula-ca-public"
        }
      }
      {
        importer: "vault"
        arguments: {
          path: $"kv/dot/external/($host)"
          allow_fail: true
        }
      }
    ]
    generations: [
      {
        generator: "nebula"
        arguments: {
          ca_private: "nebula-ca-private"
          ca_public: "nebula-ca-public"
          name: $host
          ip: $"($ip)/16"
          private: $"($host)-nebula-private"
          public: $"($host)-nebula-public"
        }
      }
      {
        generator: "moustache"
        arguments: {
          name: $"($host)-nebula-config"
          renew: true
          variables: {
            CA_PUBLIC: "nebula-ca-public"
            CERT_PRIVATE: $"($host)-nebula-private"
            CERT_PUBLIC: $"($host)-nebula-public"
          }
          template: ($nebula_base_template
            + "\n"
            + $shared.nebula-non-lighthouse)
        }
      }
    ]
    exports: [
      {
        exporter: "vault"
        arguments: {
          path: $"kv/dot/external/($host)"
        }
      }
    ]
  } | to json | cryl stdin json --stay
}

