#!/usr/bin/env bash

# Shell utils

alias x="xargs"
alias q="exit"
alias qa="exit"
alias wqa="exit"
alias :q="exit"
alias :qa="exit"
alias :wqa="exit"

# System utils

alias sudo="doas -u root"
alias sudoedit='doas -u root $SUDO_EDITOR'
alias pls="sudo"

alias up="paru -Sy && sudo powerpill -Su && paru -Su"
alias syu="sudo /usr/bin/paru -Syu"
alias sup="sudo /usr/bin/paru -Sup"

alias syshw="hwinfo --short"
alias sysinfo="inxi -Faz"
alias sysj="journalctl -p 3 -xb"

alias lsdev="paru -Qeq | rg --color=auto '\-(git|cvs|svn|bzr|darcs|always|hg)'"
alias lsbig="expac -H M '%m\t%n' | sort -h | nl"
alias clp="paru -Qtdq | paru -Rns -"
alias news="paru -Ps; paru -Pw"
alias health="paru -Qkk | rg 'warning'"

alias yas="yes"
alias bruh="nvim"

alias sis="xclip -selection clipboard"
alias slay="xclip -o -selection clipboard"

alias en-hr="trans -from en -to hr"
alias hr-en="trans -from hr -to en"

alias svirsh="virsh --connect qemu:///system"

alias ports="lsof -i"

# File utils

alias .="z ."
alias ..="z .."
alias ls="exa -al --color=always --group-directories-first --icons --group"
alias cat="bat --style header --style rule --style snip --style changes"
alias grep="rg --color=auto --max-columns=100"
alias sed="sed -E"
alias sad="sad --pager 'delta -s'"
alias tree="tree -CSAFah"
alias mv="mv -i"
alias rm="rm -i"

# Config utils

alias cshell="z ~/.config/shell; nvim"
alias cbash="z ~; vim .bashrc"
alias cfish="z ~/.config/fish; nvim config.fish"
alias czsh="z ~/.config/zsh; nvim .zshrc"
alias cstarship="z ~/.config/starship; vim starship.toml"
alias cnvim="z ~/.config/nvim; nvim"
alias cvim="z ~; vim .vimrc"
alias cranger="z ~/.config/ranger; nvim"
alias ckitty="z ~/.config/kitty; nvim kitty.conf"
alias cqtile="z ~/.config/qtile; nvim config.py"

# Agenda

alias agenda='z $REPOS/agenda; nvim'
alias todo='z $REPOS/agenda; nvim TODO.md -c ZenMode'
alias arch='z $REPOS/agenda; nvim arch.md -c ZenMode'

# Git utils

alias bro="git"
alias lg="lazygit"

# C++

alias ct="cmake --build --preset debug; ctest --preset debug"

# Ruby

alias lruby="export GEM_PATH=vendor/gem; export GEM_HOME=vendor/gem; ruby"
alias lgem="lruby -S gem"
alias lbundle="lruby -S bundle"
alias lrspec="lruby -S rspec"
alias lrake="lruby -S rake"
alias ljruby="export GEM_PATH=vendor/gem; export GEM_HOME=vendor/gem; jruby"
alias ljgem="ljruby -S gem"
alias ljbundle="ljruby -S bundle"
alias ljrspec="ljruby -S rspec"
alias ljrake="ljruby -S rake"

# Lua
alias lua="rlwrap lua"
alias luajit="rlwrap luajit"

# Other

alias rwm="qtile cmd-obj -o cmd -f restart"

export LOADED_ALIASSH=1