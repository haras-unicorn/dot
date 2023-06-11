let-env PATH = (
  $env.PATH |
  split row (char esep) |
  prepend $"($env.HOMEPATH)/bin"
)

let-env PATH = (
  $env.PATH |
  split row (char esep) |
  prepend $"($env.HOMEPATH)/scripts"
)

let-env PATH = (
  $env.PATH |
  split row (char esep) |
  prepend 'bin'
)

let-env PATH = (
  $env.PATH |
  split row (char esep) |
  prepend 'scripts'
)

let-env VIRTUAL_ENV_DISABLE_PROMPT = "1"

let-env STARSHIP_CONFIG = $"($env.HOMEPATH)/.config/starship/starship.toml"
mkdir ~/.cache/starship
starship init nu | save --force ~/.cache/starship/init.nu

zoxide init nushell --hook prompt | save --force ~/.zoxide.nu
