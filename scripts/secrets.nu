#!/usr/bin/env nu --stdin

def "main" [] {
  
}

# create the nebula vpn ca
#
# outputs:
#   ./name.vpn.pub
#   ./name.vpn
def "main vpn ca" [name: string = "haras"] {
  nebula-cert ca -name $name -duration (365 * 24 * 100)

  mv $"($name).crt" $"($name).vpn.pub"
  chmod 644 $"($name).vpn.pub"

  mv $"($name).key" $"($name).vpn"
  chmod 400 $"($name).vpn"
}

# create nebula vpn keys signed by a previously generated vpn ca
#
# outputs:
#   ./name.vpn.pub
#   ./name.vpn
def "main vpn host" [name: string, ip: string, ca: string = "haras"] {
  nebula-cert sign -ca-crt $"($ca).vpn.pub" -ca-key $"($ca).vpn" -name $name -ip $ip  

  mv $"($name).crt" $"($name).vpn.pub"
  chmod 644 $"($name).vpn.pub"

  mv $"($name).key" $"($name).vpn"
  chmod 400 $"($name).vpn"
}

# create an ssh key pair
#
# outputs:
#   ./name.ssh.pub
#   ./name.ssh
def "main ssh" [name: string] {
  ssh-keygen -q -a 100 -t ed25519 -N $name -f $"($name).ssh"
  chmod 644 $"($name).ssh.pub"
  chmod 400 $"($name).ssh"
}

# create a linux user password using mkpasswd
#
# outputs:
#   ./name.pass.pub
#   ./name.pass
def "main pass" [name: string, length: int = 32] {
  let pass = random chars --length $length
  $pass | save -f $"($name).pass.pub"
  chmod 644 $"($name).pass.pub"

  let encrypted = $pass | mkpasswd --stdin
  $encrypted | save -f $"($name).pass"
  chmod 400 $"($name).pass"
}

# create a sops secret file from a directory of secret files and encrypt it
# each file in the directory will be a secret in the resulting file
# with the name equal to the name of the file
#
# use `sops encrypt --help` to check out available private key options
#
# additionally creates an age key pair
# to be used for decryption during host activation
#
# outputs:
#   ./secrets.yaml.pub
#   ./secrets.yaml
def "main encrypt" [] {
  age-keygen | save -f "secrets.age"
  chmod 400 "secrets.age"

  open --raw "secrets.age" | age-keygen -y | save -f "secrets.age.pub"
  chmod 644 "secrets.age.pub"

  ls $env.PWD
    | where { |x| x.type == "file" }
    | each { |x| {
        let content = open --raw ([$env.PWD $x.name] | path join)
          | str trim
          | str replace "\n" "\n  "
        return $"($x.name): |\n  $(content)" 
      } }
    | str join "\n"
    | save -f "secrets.yaml"
  chmod 644 "secrets.yaml.pub"

  sops encrypt "secrets.yaml" --age "secrets.age.pub" --output "secrets.yaml.pub"
  chmod 400 "secrets.yaml"
}
