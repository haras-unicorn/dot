" OPTIONS {{{

" 1 important {{{

" }}}

" 2 moving around, searching, patterns {{{

" case insensitive
set ignorecase

" case sensitive when a pattern contains upper chars
set smartcase

" incremental search highlight
set incsearch

" }}}

" 3 tags

" 4 text display {{{

" add line numbers
set nonumber

" numbers relative to cursor
set norelativenumber

" number column width
set numberwidth=2

" set maximum scrolling offset so the cursor is always
" in the center of the screen
set scrolloff=999

" preserve indentation in wrapped text
set breakindent

" make break indentation at least 2 chars, and shift breaks by 2 chars put
" 'showbreak' at the beginning of break indented lines
set breakindentopt=min:2,shift:2,sbr

" show this at the beginning of break indented lines
set showbreak=↳

" extra info
set list
set listchars=tab:⇥\ ,trail:·
set fillchars=fold:\ ,vert:\ 

" don't redraw when executing macros
set nolazyredraw

" }}}

" 5 syntax, spelling and highlight {{{

" syntax highlighting
syntax on

" allow auto-indenting and plugins depending on file type
filetype indent on

" highlight the cursor column
set nocursorcolumn

" highlight search
set hlsearch

if has('gui')
  " use true colors in terminal
  set termguicolors
endif

" set an 80 column border for good coding style
set colorcolumn=80

" TODO: configure spell check
" set spell

" treat camel-cased words as separate
set spelloptions=camel

" }}}

" 6 multiple windows {{{

" on vsplit or vnew open a new window to the right of the current one
set splitright

" }}}

" 7 multiple tab pages

" 8 terminal

" 9 using the mouse

" 10 printing

" 11 messages and info

" 12 selecting text {{{

" use system clipboard
if has('clipboard')
  set clipboard=unnamedplus
endif

" }}}

" 13 editing text {{{

" use undo files
set undofile

" undo file directory so vim doesn't create undo files all over the place
" always starts in your $HOME directory
" double slash is to add the full path of files as name of file so
" vim can find that stuff
set undodir=~/.local/share/vim/undo//
if !isdirectory($HOME . '/.local/share/vim/undo/')
  call mkdir($HOME . '/.local/share/vim/undo/', 'p')
endif

" wrap above 80 chars
set textwidth=80

" wrap at 80 chars
set wrapmargin=80

" read ':h fo-table
set formatoptions=t,c,r,o,q,n,2,m,M,1,j,p

" read ':h 'complete'
set complete=.,w,b,u,k,s,t

" list completions in insert mode
set completeopt=menu,menuone,noselect

" use ~ like an operator to change casing
set tildeop

" join lines with '.' without adding two spaces?? this one is so weird
set nojoinspaces

" }}}

" 14 tabs and indenting {{{

" number of columns occupied by a tab
set tabstop=2

" width for auto-indents
set shiftwidth=2

" use 2 spaces when <BS> on tabs
set softtabstop=2

" use 'shiftwidth' for '<<' and '>>'
set shiftround

" converts tabs to white space
set expandtab

" indent a new line the same amount as the line just typed
set autoindent

" }}}

" 15 folding {{{

" fold with markers in comments
set foldmethod=marker

" i only want to fold this file anyway
set commentstring=\'\ %s

" maximum nesting folds
set foldnestmax=3

" set fold column width
set foldcolumn=0

" start with all folds closed
set foldlevelstart=0

" TODO: config }}}

" 16 diff mode

" 17 mapping {{{

" i would set noremap here, but that would probably break plugins

" }}}

" 18 reading and writing files {{{

" last line doesn't have end of line - this just sounds confusing when the
" character is not present
set noendofline

" i don't know why people add end-of-line at the end of a file
set nofixendofline

" Byte Order Mark at the beginning of a file is a Microsoft thing i think
set nobomb

" keep a backup file before overwriting a file
set backup

" backup file directory so vim doesn't create backup files all over
" the place
" double slash is to add the full path of files as name of file with some
" magic
set backupdir=~/.local/share/vim/backup//
if !isdirectory($HOME . '/.local/share/vim/backup/')
  call mkdir($HOME . '/.local/share/vim/backup/', 'p')
endif

" }}}

" 19 the swap file {{{

" use swap files
set swapfile

" swap file directory - double slash is to add the full path of files
" as name
" of file so vim can find that stuff
set directory=~/.local/share/vim/swap//
if !isdirectory($HOME . '/.local/share/vim/swap/')
  call mkdir($HOME . '/.local/share/vim/swap/', 'p')
endif

" num of chars to update the swap file
set updatecount=100

" time to update the swap file and CursorHold events
set updatetime=500

" }}}

" 20 command line editing {{{

" list completions in command mode
set wildmenu

" same as wilder
" TODO: configure this to a char
" set wildchar='<C-j>'

" see ':h 'wildmode''
" keeping it here in case I need it
set wildmode=longest,list

" ignore case when completing file names
" keeping it here in case I need it
set wildignorecase

" }}}

" 21 executing external commands {{{

" warn when using shell command when the buffer has changes
set warn

" }}}

" 22 running make and jumping to errors

" 23 language specific

" 24 multi-byte characters {{{

" use utf-8
set encoding=utf-8

" use utf-8 (buffer-local)
set fileencoding=utf-8

" set scriptencoding to utf-8
scriptencoding=utf-8

" emojis as full width
set emoji

" }}}

" 25 various {{{

" use g by default in substitutions
set gdefault

" what to save with view files
set viewoptions=folds,options,cursor,curdir

" view file directory
" double slash is to add the full path of files as name of file so
" vim can find that stuff
set viewdir=~/.local/share/vim/view//
if !isdirectory($HOME . '/.local/share/vim/view/')
  call mkdir($HOME . '/.local/share/vim/view/', 'p')
endif

" session
set sessionoptions=blank,buffers,curdir,folds,help,options,tabpages,winsize,resize,winpos,terminal

" python 2 is deprecated
set pyxversion=3

" other - not from ':opt'

if has('gui')
  " font
  set guifont=JetBrainsMono\ Nerd\ Font,DejaVu\ Sans\ Mono:h16

  " speed up scrolling
  set ttyfast
endif

" }}}

" }}}

" KEYMAP {{{

" leader
let g:mapleader = ' '

" search
nnoremap / /\v
nnoremap ? ?\v
cnoremap s/ s/\v
nnoremap <leader>s :%s/\v
vnoremap <leader>s :s/\v
nnoremap <leader>h <cmd>noh<cr>

" insert lines
nnoremap <leader>o $a<cr><C-c>k
nnoremap <leader>O 0i<cr><C-c>

" }}}

" CMD {{{

" }}}

" AUTOCMD {{{

augroup user_reload
  autocmd!
  autocmd BufWritePost ~/.vimrc so ~/.vimrc
augroup END

" }}}

" COLORS {{{

" material palenight from https://github.com/hzchirs/vim-material

let s:gui = { }

let s:gui.background   = '#292D3E'
let s:gui.foreground   = '#A6ACCD'
let s:gui.none         = 'NONE'
let s:gui.selection    = '#434A6C'
let s:gui.line         = '#191919'
let s:gui.comment      = '#676E95'

let s:gui.red          = '#FF5370'
let s:gui.pink         = '#F07178'
let s:gui.orange       = '#F78C6C'
let s:gui.light_yellow = '#FFE57F'
let s:gui.yellow       = '#FFCB6B'
let s:gui.green        = '#C3E88D'
let s:gui.teal         = '#39E09E'
let s:gui.light_teal   = '#69F0AE'
let s:gui.pale_blue    = '#B2CCD6'
let s:gui.cyan         = '#89DDFF'
let s:gui.blue         = '#82AAFF'
let s:gui.purple       = '#C792EA'
let s:gui.violet       = '#BB80B3'
let s:gui.brown        = '#C17E70'

function! s:hi(group, guifg, guibg, ctermfg, ctermbg, attr)
  if a:guifg !=# ''
    exec 'hi ' . a:group . ' guifg=' . a:guifg
  endif
  if a:guibg !=# ''
    exec 'hi ' . a:group . ' guibg=' . a:guibg
  endif
  if a:ctermfg !=# ''
    exec 'hi ' . a:group . ' ctermfg=' . a:ctermfg
  endif
  if a:ctermbg !=# ''
    exec 'hi ' . a:group . ' ctermbg=' . a:ctermbg
  endif
  if a:attr !=# ''
    exec 'hi ' . a:group . ' gui=' . a:attr . ' cterm=' . a:attr
  endif
endfunction

" Editor colors
call s:hi('ColorColumn',  s:gui.none,       s:gui.line,       '', '', ''         )
call s:hi('Cursor',       s:gui.yellow,     '',               '', '', ''         )
call s:hi('CursorColumn', s:gui.none,       s:gui.line,       '', '', ''         )
call s:hi('LineNr',       s:gui.comment,    '',               '', '', ''         )
call s:hi('CursorLine',   s:gui.none,       s:gui.line,       '', '', ''         )
call s:hi('CursorLineNr', s:gui.cyan,       s:gui.line,       '', '', ''         )
call s:hi('Directory',    s:gui.blue,       '',               '', '', ''         )
call s:hi('FoldColumn',   '',               s:gui.none,       '', '', ''         )
call s:hi('Folded',       s:gui.comment,    s:gui.line,       '', '', ''         )
call s:hi('PMenu',        s:gui.foreground, s:gui.line,       '', '', ''         )
call s:hi('PMenuSel',     s:gui.cyan,       s:gui.selection,  '', '', 'bold'     )
call s:hi('ErrorMsg',     s:gui.red,        s:gui.none,       '', '', ''         )
call s:hi('Error',        s:gui.red,        s:gui.none,       '', '', ''         )
call s:hi('WarningMsg',   s:gui.orange,     '',               '', '', ''         )
call s:hi('VertSplit',    s:gui.background, s:gui.foreground, '', '', ''         )
call s:hi('Conceal',      s:gui.comment,    s:gui.background, '', '', ''         )

call s:hi('DiffAdded',    s:gui.green,      '',               '', '', ''         )
call s:hi('DiffRemoved',  s:gui.red,        '',               '', '', ''         )

call s:hi('DiffAdd',      s:gui.background, s:gui.teal,       '', '', ''         )
call s:hi('DiffChange',   s:gui.background, s:gui.teal,       '', '', ''         )
call s:hi('DiffDelete',   s:gui.red,        s:gui.background, '', '', ''         )
call s:hi('DiffText',     '',               s:gui.selection,  '', '', ''         )


call s:hi('NonText',      s:gui.comment,    '',               '', '', ''         )
call s:hi('helpExample',  s:gui.blue,       '',               '', '', ''         )
call s:hi('MatchParen',   '',               s:gui.selection,  '', '', ''         )
call s:hi('Title',        s:gui.cyan,       '',               '', '', ''         )
call s:hi('Comment',      s:gui.comment,    '',               '', '', 'italic'   )
call s:hi('String',       s:gui.green,      '',               '', '', ''         )
call s:hi('Normal',       s:gui.foreground, s:gui.none,       '', '', ''         )
call s:hi('Visual',       '',               s:gui.selection,  '', '', ''         )
call s:hi('Constant',     s:gui.pink,       '',               '', '', ''         )
call s:hi('Type',         s:gui.yellow,     '',               '', '', 'none'     )
call s:hi('Define',       s:gui.cyan,       '',               '', '', ''         )
call s:hi('Statement',    s:gui.cyan,       '',               '', '', 'none'     )
call s:hi('Function',     s:gui.blue,       '',               '', '', ''         )
call s:hi('Conditional',  s:gui.cyan,       '',               '', '', ''         )
call s:hi('Float',        s:gui.orange,     '',               '', '', ''         )
call s:hi('Noise',        s:gui.cyan,       '',               '', '', ''         )
call s:hi('Number',       s:gui.orange,     '',               '', '', ''         )
call s:hi('Identifier',   s:gui.pink,       '',               '', '', ''         )
call s:hi('Operator',     s:gui.cyan,       '',               '', '', ''         )
call s:hi('PreProc',      s:gui.blue,       '',               '', '', ''         )
call s:hi('Search',       s:gui.none,       s:gui.none,       '', '', 'underline')
call s:hi('InSearch',     s:gui.background, s:gui.foreground, '', '', ''         )
call s:hi('Todo',         s:gui.red,        s:gui.foreground, '', '', 'reverse'  )
call s:hi('Special',      s:gui.orange,     '',               '', '', ''         )
call s:hi('SignColumn',   '',               s:gui.none,       '', '', ''         )

" }}}