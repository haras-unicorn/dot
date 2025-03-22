#!/usr/bin/env nu

let self = [ $env.FILE_PWD "hosts.nu" ] | path join
let root = $env.FILE_PWD | path dirname

def main [] {
  nu -c $"($self) --help"
}
