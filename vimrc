source $VIMRUNTIME/defaults.vim
set mouse=
"set mouse-=a

"filetype off
"force 256 colors
"set t_Co=256
"" set Vim-specific sequences for RGB colors
"colorscheme bubblegum-256-dark
color jellybeans
"color zenburn
set background=dark

"if (has("termguicolors"))
"  set termguicolors
"  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
"  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
"endif

"add cursorline
set cursorline
"highlight CursorLine ctermbg=234 ctermfg=none cterm=none

"leave background alone if running in terminal
if !has("gui_running")
  autocmd ColorScheme * highlight Normal ctermbg=NONE guibg=NONE
endif

"autocmd ColorScheme * highlight Visual ctermfg=None ctermbg=237 cterm=None
"autocmd ColorScheme * highlight StatusLine ctermbg=239 ctermfg=white


filetype plugin indent on
syntax enable

"filetype plugin indent on    " required
"filetype off

"just disable backup/swap files
set noswapfile
set nobackup

"change cwd to that of file opened
set autochdir

"write changes to vimrc?
set modifiable

"gvim
"if has('gui_running')
"set guifont=Terminus\ 10
"colorscheme evening
"colorscheme delek
"colors evening
"endif

"key mappings


"
"tabs
:map <F7> :tabp <CR>
:map <F8> :tabn <CR>
:map <F9> :tabe <CR>:E <CR>
":map <F9> :tabe %:h <CR>
"
:map <C-S-n> :set invnumber<CR>


" file is large from 10mb
let g:LargeFile = 1024 * 1024 * 10
augroup LargeFile
    autocmd BufReadPre * let f=getfsize(expand("<afile>")) | if f > g:LargeFile || f == -2 | call LargeFile() | endif
augroup END

function LargeFile()
    " no syntax highlighting etc
    set eventignore+=FileType
    " save memory when other file is viewed
    setlocal bufhidden=unload
    " is read-only (write with :w new_filename)
    setlocal buftype: ""
    "setlocal buftype=nowrite
    " no undo possible
    setlocal undolevels=-1
    " display message
    autocmd VimEnter *  echo "The file is larger than " . (g:LargeFile / 1024 / 1024) . " MB, so some options are changed (see .vimrc for details)."
endfunction

"don't wrap git commit messages
autocmd Syntax gitcommit setlocal textwidth=0
autocmd BufNewFile,BufRead *.html set syntax=php

"set paste

"let php_folding = 1        "Set PHP folding of classes and functions.
"let php_htmlInStrings = 1  "Syntax highlight HTML code inside PHP strings.
"let php_sql_query = 1      "Syntax highlight SQL code inside PHP strings.
"let php_noShortTags = 1    "Disable PHP short tags.
"set nocompatible          " Because filetype detection doesn't work well in compatible mode
"filetype plugin indent on " Turns on filetype detection, filetype plugins, and filetype indenting all of which add nice extra features to whatever language you're using
"syntax enable             " Turns on filetype detection if not already on, and then applies filetype-specific highlighting.

"set foldmethod=indent
set ruler



"set shiftwidth=4
"set softtabstop=4
"highlight! link DiffText MatchParen

"highlight DiffAdd cterm=none ctermfg=bg ctermbg=Green gui=none guifg=bg guibg=Green
"highlight DiffDelete cterm=none ctermfg=bg ctermbg=Red gui=none guifg=bg guibg=Red
"highlight DiffChange cterm=none ctermfg=bg ctermbg=Yellow gui=none guifg=bg guibg=Yellow
"highlight DiffText cterm=none ctermfg=bg ctermbg=Magenta gui=none guifg=bg guibg=Magenta



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sets how many lines of history VIM has to remember
set history=500

"Always show current position
set ruler

" Highlight search results
set hlsearch

" For regular expressions turn magic on
set magic

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" vim -b : edit binary using xxd-format!
augroup Binary
  au!
  au BufReadPre  *.bin let &bin=1
  au BufReadPost *.bin if &bin | %!xxd
  au BufReadPost *.bin set ft=xxd | endif
  au BufWritePre *.bin if &bin | %!xxd -r
  au BufWritePre *.bin endif
  au BufWritePost *.bin if &bin | %!xxd
  au BufWritePost *.bin set nomod | endif
augroup END


""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
"set statusline=\ %F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

"set  rtp+=/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim/
""""source /usr/share/vim/addons/plugin/powerline.vim


function! Preserve(command)
    " Preparation: save window state
    let l:saved_winview = winsaveview()
    " Run the command:
    execute a:command
    " Clean up: restore previous window position
    call winrestview(l:saved_winview)
endfunction

"remove trailing whitespace and reformat without losing postition
nnoremap <F5> :call Preserve("normal gg=G") <BAR>:call Preserve("%s/\\s\\+$//e")<CR>

set noshowmode

let g:airline_powerline_fonts = 1
"let g:airline_theme='base16_ashes'
set runtimepath^=~/.vim/bundle/vim-airline
"set runtimepath^=~/.vim/bundle/vim-airline-themes


"slow inserts
"set foldmethod=syntax
"set foldlevel=999

set guioptions+=a

set display+=uhex

"""ss format
set expandtab
set tabstop=2
set shiftwidth=2

autocmd FileType c setlocal noexpandtab softtabstop=0 shiftwidth=4
autocmd FileType sh setlocal noexpandtab softtabstop=0 shiftwidth=4
:set tabstop=4
