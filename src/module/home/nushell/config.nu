$env.config = {
  show_banner: false

  edit_mode: vi
  cursor_shape: {
    vi_insert: line
    vi_normal: underscore
  }

  hooks: {
    env_change: {
      PWD: { || direnv export json | from json | default {} | load-env }
    }
  }

  table: {
    mode: with_love
  }
}

alias pls = sudo;
alias rm = rm -i;
alias mv = mv -i;
alias yas = yes;

# fastfetch
