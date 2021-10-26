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
" - vim-signature
" - vim-slime
" - vim-ipython-cell
" - SimplyFold
" - vim-fugitive
" - vim-startify
" - vim-maximizer
" - vim-surround
"
" author: Uthpala Herath
" my fork: https://github.com/uthpalaherath/vimrc

:set encoding=utf-8
:set fileencoding=utf-8

""" change current working directory to file dir
autocmd BufEnter * silent! lcd %:p:h


""" vim settings
:set splitright
:set splitbelow

" start in insert mode only if file is empty
autocmd BufNewFile * startinsert
" function InsertIfEmpty()
"     if @% == ""
"         " No filename for current buffer
"         startinsert
"     elseif filereadable(@%) == 0
"         " File doesn't exist yet
"         startinsert
"     elseif line('$') == 1 && col('$') == 1
"         " File is empty
"         startinsert
"     endif
" endfunction
" au VimEnter * call InsertIfEmpty()

""" indentLine
let g:indentLine_char = '¦'

"""" ale
let g:ale_linters = {'python':['flake8','pydocstyle']}
let g:ale_fixers = {'*':['remove_trailing_lines','trim_whitespace'], 'python':['black']}
let g:ale_fix_on_save = 1
let g:ale_lint_on_enter = 0 """ Don't lint when opening a file
let g:ale_sign_error = '•'
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
noremap <silent> <leader>y "+y
noremap <silent> <leader>Y "+Y
noremap <silent> <leader>p "+p
noremap <silent> <leader>P "+P

""" paste without yanking replaced text in visual mode
vnoremap <silent> p "_dP
vnoremap <silent> P "_dp

""" multi-platform clipboard
"set clipboard^=unnamed,unnamedplus
"set clipboard=unnamedplus

""" Get rid of annoying autocomment in new line
au FileType * set fo-=c fo-=r fo-=o

""" YCM options
let g:ycm_complete_in_comments=0
let g:ycm_collect_identifiers_from_tags_files=1
let g:ycm_min_num_of_chars_for_completion=1
let g:ycm_cache_omnifunc=0
let g:ycm_seed_identifiers_with_syntax=1
let g:ycm_autoclose_preview_window_after_insertion = 1
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_auto_hover=''
let g:ycm_goto_buffer_command = 'new-or-existing-tab'
"set updatetime=1000
"set completeopt-=preview
set completeopt+=popup
nmap <leader>d <plug>(YCMHover)
nnoremap <silent> <leader>gd :YcmCompleter GoTo<CR>

""" gitgutter
let g:gitgutter_enabled = 1
" Colors
let g:gitgutter_override_sign_column_highlight = 0
highlight GitGutterAdd ctermfg=2
highlight GitGutterChange ctermfg=3
highlight GitGutterDelete ctermfg=1
highlight GitGutterChangeDelete ctermfg=4

""" split screen shortcuts
nnoremap <C-W>- :new<CR>
nnoremap <C-W>\ :vnew<CR>

""" visual marks
nnoremap <leader>m :SignatureRefresh<cr>

""" run python scripts within vim with F9
"autocmd Filetype python nnoremap <buffer> <F5> :w<CR>:vert ter python3 "%"<CR>
autocmd FileType python map <buffer> <F9> :w<CR>:exec '!python' shellescape(@%, 1)<CR>
autocmd FileType python imap <buffer> <F9> <esc>:w<CR>:exec '!python' shellescape(@%, 1)<CR>

""" changesPlugin
let g:changes_use_icons=0

""" Fortran line lengths
":let b:fortran_fixed_source=0
":set syntax=fortran

" Enable folding
set foldmethod=indent
set foldlevel=99
" set nofoldenable
set foldcolumn=0


""" vim-pydocstring
let g:pydocstring_doq_path = '/usr/local/bin/doq'
let g:pydocstring_formatter = 'numpy'
let g:pydocstring_templates_path = '~/.vim_runtime/pydocstringtemplates'

""" vim-slime
let g:slime_target = "vimterminal"
let g:ipython_cell_delimit_cells_by = "marks"
" fix paste issues in ipython
let g:slime_python_ipython = 1
let g:slime_dont_ask_default = 1

" map <Leader>s to start IPython
"nnoremap <Leader>s :vert term <CR> :SlimeSend1 ipython --matplotlib<CR>
nnoremap <Leader>s :vert term <CR> ipython --matplotlib<CR> <c-w><c-p> :SlimeConfig <CR>
nnoremap <Leader>S :term <CR> ipython --matplotlib<CR> <c-w><c-p> :SlimeConfig <CR>

" map <Leader>r to run script
nnoremap <Leader>r :IPythonCellRun<CR>

" map <Leader>R to run script and time the execution
nnoremap <Leader>R :IPythonCellRunTime<CR>

" map <Leader>c to execute the current cell
nnoremap <Leader>c :IPythonCellExecuteCell<CR>

" map <Leader>C to execute the current cell and jump to the next cell
nnoremap <Leader>C :IPythonCellExecuteCellJump<CR>

" map <Leader>l to clear IPython screen
nnoremap <Leader>l :IPythonCellClear<CR>

" map <Leader>x to close all Matplotlib figure windows
nnoremap <Leader>x :IPythonCellClose<CR>

" map [c and ]c to jump to the previous and next cell header
nnoremap [c :IPythonCellPrevCell<CR>
nnoremap ]c :IPythonCellNextCell<CR>

" map <Leader>h to send the current line or current selection to IPython
nmap <Leader>h <Plug>SlimeLineSend
xmap <Leader>h <Plug>SlimeRegionSend

" map <Leader>p to run the previous command
"nnoremap <Leader>p :IPythonCellPrevCommand<CR>

" map <Leader>Q to restart ipython
nnoremap <Leader>qq :IPythonCellRestart<CR>

" map <Leader> q to reset variables
nnoremap <Leader>q :SlimeSend1 %reset -f<CR>

" map <Leader>d to start debug mode
"nnoremap <Leader>d :SlimeSend1 %debug<CR>

" map <Leader>q to exit debug mode or IPython
"nnoremap <Leader>q :SlimeSend1 exit<CR>

""" Startify
let g:startify_session_persistence = 1
let g:startify_lists = [
      \ { 'type': 'sessions',  'header': ['   Sessions']       },
      \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
      \ ]
let g:startify_bookmarks = [ '~/.vim_runtime/my_configs.vim' ]

""" vim-maximizer
let g:maximizer_default_mapping_key = '<C-W>z'
nnoremap <silent><C-W>z :MaximizerToggle<CR>
vnoremap <silent><C-W>z :MaximizerToggle<CR>gv
inoremap <silent><C-W>z <C-o>:MaximizerToggle<CR>

""" snip-mate
let g:snipMate = { 'snippet_version' : 1 }

""" inner slashes
onoremap <silent> i/ :<C-U>normal! T/vt/<CR>
onoremap <silent> a/ :<C-U>normal! F/vf/<CR>

""" delete buffer when navigating back
map <silent> <C-o> :bdelete<CR>
