scripts := absolute_path('scripts')
root := absolute_path('')

format:
  shfmt --write {{root}}
  prettier --write {{root}}
  nixpkgs-fmt {{root}}

lint:
  shellcheck {{scripts}}/*
  prettier --check {{root}}

part *args:
  "{{scripts}}"/part {{args}}

mkpass *args:
  "{{scripts}}"/mkpass {{args}}

mkage *args:
  "{{scripts}}"/mkage {{args}}

mkssh *args:
  "{{scripts}}"/mkssh {{args}}

mkvpn *args:
  "{{scripts}}"/mkvpn {{args}}

mksops *args:
  "{{scripts}}"/mksops {{args}}

install *args:
  "{{scripts}}"/install {{args}}

image *args:
  "{{scripts}}"/image {{args}}

codext *args:
  "{{scripts}}"/codext {{args}} > "{{root}}/src/module/home/code/extensions.nix"
  nixpkgs-fmt "{{root}}/src/module/home/code/extensions.nix"
