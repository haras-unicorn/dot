def "main" []: nothing -> nothing {
  nu $"($env.FILE_PWD)/($env.FILE_NAME)" -h
}

# Run detection on this machine
def "main detect" []: nothing -> nothing {
  cd (flake-root)
  let result = sudo nixos-facter | complete

  if $result.exit_code != 0 {
    print -e $"nixos-facter exited with code ($result.exit_code)."
    print -e $"stderr:\n($result.stderr)\n"
    print -e $"stdout:\n($result.stdout)\n"
    exit 1
  }

  $result.stdout
    | prettier --parser json
    | save -f ([ "assets" "hardware" $"(etc hostname).json" ] | path join)
}

# Format repository
def "main format" []: nothing -> nothing {
  cd (flake-root)
  prettier --write .
  nixfmt ...(fd '.*\.nix$' . | lines)
}

# Lint the repository
def "main lint" []: nothing -> nothing {
  cd (flake-root)
  prettier --check .
  nixfmt --check ...(fd '.*\.nix$' . | lines)
  markdownlint --ignore-path .gitignore .
  cspell lint . --no-progress
  if $env.NIX_BUILD_TOP? == null {
    let md_result = (
      markdown-link-check
        --config ./.markdown-link-check.json
        ...(fd '^.*.md$' . | lines)
      | rg -q error
      | complete
    )
    if $md_result.exit_code == 0 {
      print -e $"Markdownlint exited with code ($md_result.exit_code)."
      print -e $"Stderr:\n($md_result.stderr)\n"
      print -e $"Stdout:\n($md_result.stdout)\n"
      exit 1
    }
  }
}

# Check which packages would be built or downloaded
# when switching machine to repository configuration
def --wrapped "main rebuild report" [
  ...args: string
]: nothing -> nothing {
  cd (flake-root)
  sudo nixos-rebuild dry-build --flake $"($env.PWD)#(etc hostname)" ...($args)
}

# Rebuild and switch machine to repository configuration
def --wrapped "main rebuild switch" [
  ...args: string
]: nothing -> nothing {
  cd (flake-root)
  sudo nixos-rebuild switch --flake $"($env.PWD)#(etc hostname)" ...($args)
}

# Rebuild and set boot entry of machine to repository configuration
def --wrapped "main rebuild boot" [
  ...args: string
]: nothing -> nothing {
  cd (flake-root)
  sudo nixos-rebuild boot --flake $"($env.PWD)#(etc hostname)" ...($args)
}

def "etc hostname" [] {
  open --raw /etc/hostname | str trim
}
