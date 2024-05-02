set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := justfile_directory()
scripts := absolute_path('scripts')
src := absolute_path('src')

format:
  shfmt --write "{{root}}"
  prettier --write "{{root}}"
  nixpkgs-fmt "{{root}}"
  yapf --recursive --in-place --parallel "{{root}}"

lint:
  let result = glob '{{root}}/**/*.sh' | \
    par-each { |x| shellcheck $x } | \
    filter { |x| $x != "" }; \
  if ($result | is-empty) { \
    exit 0; \
  } else { \
    echo ($result | str join); \
    exit 1; \
  }

  ruff check "{{root}}"
  prettier --check "{{root}}"

  let result = glob '{{root}}/**/*.nix' | \
    par-each { |x| nil diagnostics $x } | \
    filter { |x| $x != "" }; \
  if ($result | is-empty) { \
    exit 0; \
  } else { \
    echo ($result | str join); \
    exit 1; \
  }
