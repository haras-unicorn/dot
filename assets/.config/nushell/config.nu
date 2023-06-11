let-env config = {
  show_banner: false
  edit_mode: vi
  cursor_shape: {
    vi_insert: line
    vi_normal: underscore
  }
}

let-env PROMPT_INDICATOR_VI_INSERT = "λ "
let-env PROMPT_INDICATOR_VI_NORMAL = " "

alias lg = lazygit
alias ld = lazydocker
alias cat = open --raw
alias pwd = echo $env.PWD
alias dl = curl --location --max-redirs 1 --max-time 900

source ~/.cache/starship/init.nu
source ~/.zoxide.nu
