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
  "{{scripts}}"/part.sh {{args}}

mkpass *args:
  "{{scripts}}"/mkpass.sh {{args}}

mkage *args:
  "{{scripts}}"/mkage.sh {{args}}

mkssh *args:
  "{{scripts}}"/mkssh.sh {{args}}

mkvpn *args:
  "{{scripts}}"/mkvpn.sh {{args}}

mksops *args:
  "{{scripts}}"/mksops.sh {{args}}

install *args:
  "{{scripts}}"/install.sh {{args}}

image *args:
  "{{scripts}}"/image.sh {{args}}

codext *args:
  "{{scripts}}"/codext.py "{{root}}/src/module/home/code/extensions.json"
  prettier --write "{{root}}/src/module/home/code/extensions.json"
