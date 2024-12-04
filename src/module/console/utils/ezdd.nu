#!/usr/bin/env nu

def "main" [input?: path, output?: path]: nothing -> nothing {
  mut input = $input
  mut output = $output

  if (($input | is-empty) or ($output | is-empty)) {
    $input = ^gum input --placeholder "" --header "Input device"
    $output = ^gum input --placeholder "" --header "Output device"
  }

  pv --interval 1 $input | dd $"of=($output)" bs=4M conv=sync,noerror
  sync
}
