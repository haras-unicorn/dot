set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := justfile_directory()
secrets-script := absolute_path('scripts/secrets.nu')
secrets-dir := absolute_path('secrets')
hosts := absolute_path('src/host')

default:
    @just --choose

format:
    cd '{{ root }}'; just --unstable --fmt
    prettier --write '{{ root }}'
    nixpkgs-fmt '{{ root }}'

lint:
    prettier --check '{{ root }}'

secrets *args:
    mkdir '{{ secrets-dir }}'
    cd '{{ secrets-dir }}'; {{ secrets-script }} {{ args }}

copy-secret-vals:
    let secrets = ls '{{ secrets-dir }}' \
      | where { |x| $x.name | str ends-with ".scrt.val.pub" } \
    for $secret in $ secrets { \
      let host = $x.name \
        | path basename \
        | parse "{host}.scrt.val.pub" \
        | get host \
      cp -f $secret.name $"{{ hosts }}/($host)/secrets.yaml" \
    }

copy-secret-key:
    let host = open --raw /etc/hostname \
    (cp -f \
      $"{{ secrets-dir }}/($host).scrt.key" \
      /root/.sops/secrets.age)
    chown root:root /root/.sops/secrets.age
    chmod 400 /root/.sops/secrets.age
