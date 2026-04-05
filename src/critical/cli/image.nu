# TODO: age location from configuration

def "main image" [host?: string, --format: string] {
  let wd = pwd
  let tmp = mktemp -d
  cd $tmp

  let host = dot host pick --with-secrets $host
  let format = if $format == null { "sd-aarch64" } else { $format }

  let raw = (nixos-generate
    --show-trace
    --system $host.system.nixpkgs.system
    --format $format
    --flake $"(dot flake)#($host.configuration)")

  let compressed = ls ($raw
    | path dirname --num-levels 2
    | path join "sd-image")
    | get name
    | first
  unzstd $compressed -o image.img
  chmod 644 image.img

  let age = $host.secrets."age-private"
    | str replace -a "\\" "\\\\"
    | str replace -a "\n" "\\n"
    | str replace -a "\"" "\\\""

  let commands = $"run
mount /dev/sda2 /
mkdir-p /root
chmod 700 /root
write /root/host.scrt.key \"($age)\"
chmod 400 /root/host.scrt.key
exit"

  echo $commands | guestfish --rw -a image.img
  mv image.img $wd

  cd $wd
  rm -rf $tmp
}
