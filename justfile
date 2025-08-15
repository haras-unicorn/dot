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

rebuild *args:
    sudo nixos-rebuild switch \
      --flake $"{{ root }}#(hostname)-((uname).machine)-linux" \
      {{ args }}

hosts *args:
    {{ root }}/scripts/hosts.nu {{ args }}
