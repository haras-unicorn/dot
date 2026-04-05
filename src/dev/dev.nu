def "main format" [] {
  cd (flake-root)
  prettier --write (flake-root)
  nixfmt ...(fd '.*.nix$' (flake-root) | lines)
}

def "main lint" [] {
  cd (flake-root)
  prettier --check (flake-root)
  nixfmt --check ...(fd '.*.nix$' (flake-root) | lines)
  markdownlint --ignore-path .gitignore (flake-root)
  cspell lint (flake-root) --no-progress
  if (markdown-link-check
    --config (flake-root)
    ...(fd '^.*.md$' (flake-root) | lines)
    | rg -q error
    | complete
    | get exit_code) == 0 {
    exit 1
  }
}
