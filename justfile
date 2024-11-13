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

copy-secrets:
    cp -f '{{ secrets-dir }}/puffy.sops.pub' '{{ hosts }}/puffy/secrets.yaml'
    cp -f '{{ secrets-dir }}/hearth.sops.pub' '{{ hosts }}/hearth/secrets.yaml'
    cp -f '{{ secrets-dir }}/workbug.sops.pub' '{{ hosts }}/workbug/secrets.yaml'
    cp -f '{{ secrets-dir }}/officer.sops.pub' '{{ hosts }}/officer/secrets.yaml'

copy-secret-key name:
    cp -f '{{ secrets-dir }}/{{ name }}.age' /root/.sops/secrets.age
    chown root:root /root/.sops/secrets.age
    chmod 400 /root/.sops/secrets.age
