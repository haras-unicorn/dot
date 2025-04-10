#!/usr/bin/env nu

def "main" [] {
  (nix flake metadata --json
    | from json
    | get locks.nodes
    | transpose key value
    | get key
    | where $it != "nixpkgs-unstable"
    | each { nix flake update $in })
}
