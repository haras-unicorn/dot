def "main test" [] {
  cd (flake-root)
  nix flake check --all-systems
  nix-unit --flake .#tests
}

def --wrapped "main test e2e" [
  test: string,
  ...args: string
] {
  cd (flake-root)
  (nix build
    $".#checks.x86_64-linux.\"($test)\".withSshBackdoor"
    --option sandbox-paths /dev/vhost-vsock
    ...($args))
}

def --wrapped "main test e2e interactive" [
  test: string,
  ...args: string
] {
  cd (flake-root)
  (nix run
    $".#checks.x86_64-linux.\"($test)\".withSshBackdoor.driverInteractive"
    --option sandbox-paths /dev/vhost-vsock
    ...($args))
}

def --wrapped "main test unit" [
  test: string,
  ...args: string
] {
  cd (flake-root)
  nix-unit --flake ".#tests" ...($args) out+err>| grep $test
}
