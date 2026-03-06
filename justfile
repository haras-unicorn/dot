set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := absolute_path('')

default:
    @just --choose

format:
    cd '{{ root }}'; just --unstable --fmt
    prettier --write '{{ root }}'
    nixfmt ...(fd '.*.nix$' '{{ root }}' | lines)

lint:
    cd '{{ root }}'; just --unstable --fmt --check
    prettier --check '{{ root }}'
    nixfmt --check ...(fd '.*.nix$' '{{ root }}' | lines)
    markdownlint --ignore-path .gitignore '{{ root }}'
    cspell lint '{{ root }}' --no-progress
    if (markdown-link-check \
      --config '{{ root }}/.markdown-link-check.json' \
      ...(fd '^.*.md$' '{{ root }}' | lines) \
      | rg -q error \
      | complete \
      | get exit_code) == 0 { exit 1 }

test:
    nix flake check --all-systems
    nix-unit --flake .#tests

test-e2e test *args:
    nix build \
      `.#checks.x86_64-linux."{{ test }}"` \
      --option sandbox-paths /dev/vhost-vsock \
      {{ args }}

test-e2e-interactive test *args:
    nix run \
      `.#checks.x86_64-linux."{{ test }}".driverInteractive` \
      --option sandbox-paths /dev/vhost-vsock \
      {{ args }}

test-unit test *args:
    nix-unit --flake .#tests out+err>| grep `{{ test }}` {{ args }}

rebuild-switch *args:
    sudo nixos-rebuild switch \
      --flake $"{{ root }}#(hostname)" \
      {{ args }}

rebuild-boot *args:
    sudo nixos-rebuild boot \
      --flake $"{{ root }}#(hostname)" \
      {{ args }}

hosts *args:
    {{ root }}/scripts/hosts.nu {{ args }}
