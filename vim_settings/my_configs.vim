" my_configs.vim is a link to ~/.vimrc
"
" This file contains my personal changes to amix's Ultimate
" Vim configuration from https://github.com/amix/vimrc.
" A lot of these code segments are gathered from around the internet
" from answers given by smart people.
"
" Follow instructions on the repo and then modify this file
" in the ~/.vim_runtime directory. It is automatically linked
" to ~/.vimrc after following the instructions.
"
" Plugins
" - changesPlugin
" - indentLine
" - molokai
" - vim-autoread
" - vim-gitgutter
" - vim-pydocstring
" - YouCompleteMe
"
" author: Uthpala Herath
" my fork: https://github.com/uthpalaherath/vimrc

""" vim settings
:set splitright
:set splitbelow

" start in insert mode only if file is empty
function InsertIfEmpty()
    if @% == ""
        " No filename for current buffer
        startinsert
    elseif filereadable(@%) == 0
        " File doesn't exist yet
        startinsert
    elseif line('$') == 1 && col('$') == 1
        " File is empty
        startinsert
    endif
endfunction
au VimEnter * call InsertIfEmpty()

""" indentLine
let g:indentLine_char = '¦'

"""" ale
let g:ale_linters = {'python':['flake8','pydocstyle']}
let g:ale_fixers = {'*':['remove_trailing_lines','trim_whitespace'], 'python':['black']}
let g:ale_fix_on_save = 1
let g:ale_lint_on_enter = 0 """ Don't lint when opening a file
let g:ale_sign_error = '●'
let g:ale_sign_warning = '.'
autocmd VimEnter * :let g:ale_change_sign_column_color = 0
autocmd VimEnter * :highlight! ALEErrorSign ctermfg=9 ctermbg=NONE
autocmd VimEnter * :highlight! ALEWarningSign ctermfg=11 ctermbg=NONE
autocmd VimEnter * :highlight! ALEInfoSign   ctermfg=14 ctermbg=NONE
autocmd VimEnter * :highlight! ALEError ctermfg=9 ctermbg=NONE
autocmd VimEnter * :highlight! ALEWarning ctermfg=11 ctermbg=NONE
autocmd VimEnter * :highlight! ALEInfo   ctermfg=14 ctermbg=NONE

function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? 'OK' : printf(
        \   '%d⨉ %d⚠ ',
        \   all_non_errors,
        \   all_errors
        \)
endfunction
set statusline+=%=
set statusline+=\ %{LinterStatus()}

""" Setting numbering
:set number relativenumber
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END

"""" toggle line numbers
noremap <silent> <F3> :set invnumber invrelativenumber<CR>

""" toggle indentLines and gitgutter
noremap <silent> <F4> :GitGutterToggle<CR> :IndentLinesToggle<CR>

""""" Remapping keys
:imap jk <ESC>`^

"""" Tab settings
set tabstop=4           """ width that a <TAB> character displays as
set expandtab           " convert <TAB> key-presses to spaces
set shiftwidth=4        " number of spaces to use for each step of (auto)indent
set softtabstop=4       " backspace after pressing <TAB> will remove up to this many spaces
set autoindent          " copy indent from current line when starting a new line
set smartindent         " even better autoindent (e.g. add indent after '{')'}')

""" NERDtree configuration
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let NERDTreeQuitOnOpen = 1

function! StartUp()
    if 0 == argc()
        NERDTree
    end
endfunction
autocmd VimEnter * call StartUp()
au VimEnter * wincmd h
:let g:NERDTreeShowLineNumbers=0
:autocmd BufEnter NERD_* setlocal nornu
let NERDTreeIgnore=['\.o$', '\.pyc$', '\.pdf$', '\.so$' ]

""" colors
:colorscheme molokai
highlight Normal ctermbg=NONE
highlight LineNr ctermbg=NONE
highlight clear SignColumn

""" paste without auto-indent
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"
inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
function! XTermPasteBegin()
set pastetoggle=<Esc>[201~
set paste
return ""
endfunction

""" copy to buffer (Only works on Mac)
map <C-c> y:e ~/clipboard<CR>P:w! !pbcopy<CR><CR>:bdelete!<CR>

""" yank/paste to/from the OS clipboard
noremap <silent> <leader>y "*y
noremap <silent> <leader>Y "*Y
noremap <silent> <leader>p "*p
noremap <silent> <leader>P "*P

""" paste without yanking replaced text in visual mode
vnoremap <silent> p "_dP
vnoremap <silent> P "_dp

""" multi-platform clipboard
" set clipboard^=unnamed,unnamedplus
" set clipboard=unnamedplus

""" Get rid of annoying autocomment in new line
au FileType * set fo-=c fo-=r fo-=o

""" YCM options
let g:ycm_complete_in_comments=0
let g:ycm_collect_identifiers_from_tags_files=1
let g:ycm_min_num_of_chars_for_completion=1
let g:ycm_cache_omnifunc=0
let g:ycm_seed_identifiers_with_syntax=1
let g:ycm_autoclose_preview_window_after_completion = 1
set completeopt-=preview

""" gitgutter
let g:gitgutter_enabled = 1
" Colors
let g:gitgutter_override_sign_column_highlight = 0
highlight GitGutterAdd ctermfg=2
highlight GitGutterChange ctermfg=3
highlight GitGutterDelete ctermfg=1
highlight GitGutterChangeDelete ctermfg=4

""" split screen shortcuts
nnoremap <C-a>-- :new<CR>
nnoremap <C-a>\\ :vnew<CR>

""" run python scripts within vim with F5
autocmd Filetype python nnoremap <buffer> <F5> :w<CR>:vert ter python3 "%"<CR>

""" changesPlugin
let g:changes_use_icons=0

""" Fortran line lengths
":let b:fortran_fixed_source=0
":set syntax=fortran

""" vim-pydocstring
let g:pydocstring_doq_path = '~/anaconda3/bin/doq'
let g:pydocstring_formatter = 'numpy'
let g:pydocstring_templates_path = '~/.vim_runtime/pydocstringtemplates'
