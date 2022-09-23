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
" - indentLine
" - molokai
" - vim-autoread
" - vim-gitgutter
" - vim-python-docstring
" - YouCompleteMe
" - vim-signature
" - vim-slime
" - vim-ipython-cell
" - vim-fugitive
" - vim-startify
" - vim-maximizer
" - vim-surround
" - vimtex
" - ultisnips
" - thesaurus_query.vim
" - vim-ycm-latex-semantic-completer (in $HOME/.vim_runtime/my_plugins/YouCompleteMe/third_party/ycmd/ycmd/completers/tex/)
" - limelight.vim
" - vim-pencil
" - vim-smoothie
" - writer.vim
" - vim-fanfingtastic
" - vim-latexfmt
" - vim-litecorrect
" - vim-textobj-sentence (depends on vim-textobj-user)
" - nerdtree-git-plugin
"
" author: Uthpala Herath
" my fork: https://github.com/uthpalaherath/vimrc

:set encoding=utf-8
:set fileencoding=utf-8
:set display=lastline    " Show as much as possible of a wrapped last line, not just @.

""" change current working directory to file dir
autocmd BufEnter * silent! lcd %:p:h

""" vim settings
:set splitright
:set splitbelow

" start in insert mode only if file is empty
"autocmd BufNewFile * startinsert
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

""" ale
let g:ale_linters = {'python':['flake8', 'pydocstyle'], 'tex':['proselint', 'writegood', 'vale']}
let g:ale_fixers = {'*':['remove_trailing_lines', 'trim_whitespace'], 'python':['black']}
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

" flake8 file
let g:syntastic_python_flake8_config_file='~/dotfiles/vim-settings/.flake8'

" disable ALE for tex files
autocmd BufEnter *.tex ALEDisable

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
function! NumControl()
    :set number relativenumber
    :augroup numbertoggle
    :  autocmd!
    :  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
    :  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
    :augroup END

    " turn off all numbers for tex files
    if &ft == "tex"
        :set nonu nornu
        :augroup numbertoggle
        :  autocmd!
        :  autocmd BufEnter,FocusGained,InsertLeave * set norelativenumber
        :  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
        :augroup END
    endif
endfunction
autocmd VimEnter * call NumControl()

"""" toggle line numbers
noremap <silent> <F3> :set invnumber invrelativenumber<CR>

""" toggle indentLines and gitgutter
noremap <silent> <F4> :IndentLinesToggle<CR>
noremap <silent> <F5> :GitGutterToggle<CR>

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

" set autochdir
" let NERDTreeChDirMode=2
" nnoremap <leader>nn :NERDTree .<CR>

""" colors
filetype plugin on
set t_Co=256
"syntax on
"set termguicolors
colorscheme molokai
"highlight Normal ctermbg=NONE
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
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)

""" split screen shortcuts
nnoremap <C-W>- :new<CR>
nnoremap <C-W>\ :vnew<CR>

""" visual marks
nnoremap <leader>m :SignatureRefresh<CR>

""" run python scripts within vim with F9
"autocmd Filetype python nnoremap <buffer> <F5> :w<CR>:vert ter python3 "%"<CR>
autocmd FileType python map <buffer> <F9> :w<CR>:exec '!/Users/uthpala/.conda/envs/py3/bin/python' shellescape(@%, 1)<CR>
autocmd FileType python imap <buffer> <F9> <esc>:w<CR>:exec '!/Users/uthpala/.conda/envs/py3/bin/python' shellescape(@%, 1)<CR>

""" changesPlugin
let g:changes_use_icons=0

""" Fortran line lengths
":let b:fortran_fixed_source=0
":set syntax=fortran

" Enable folding
"set foldmethod=indent
"set foldlevel=99
" set nofoldenable
"set foldcolumn=0

""" vim-python-docstring
let g:python_style = 'numpy'

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

" map terminal scroll to Ctrl+b
tnoremap <c-b> <c-\><c-n>

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
"map <silent> <C-o> :bdelete<CR>

""" cursor options
:autocmd InsertEnter * set cul
:autocmd InsertLeave * set nocul

" cursor style
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Disable all blinking:
:set guicursor+=a:blinkon0
" reset cursor when vim exits
autocmd VimLeave * silent !echo -ne "\e[6 q""]"

""" resume cursor location, except for github commits
augroup vimStartup
au!
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif
augroup END

""" auto-pair modifications
let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '```':'```', '"""':'"""', "'''":"'''", "`":"`",'$':'$'}

""" ctags
nnoremap <leader>. :CtrlPTag<cr>
set tags+=tags;/

" Open the definition in a new tab
:nnoremap <silent><Leader><C-]> <C-w><C-]><C-w>T

" Open the definition in a vertical split
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

""" nerdtree-git-plugin
let g:NERDTreeGitStatusConcealBrackets = 0 " default: 0
let g:NERDTreeGitStatusShowClean = 0 " default: 0

""" ---------- LATEX SETTINGS ----------

let g:vimtex_compiler_latexmk = {
        \ 'executable' : 'latexmk',
        \ 'options' : [
        \   '-lualatex',
        \   '-file-line-error',
        \   '-synctex=1',
        \   '-interaction=nonstopmode',
        \ ],
        \}

""" vimtex
let g:vimtex_view_method = 'skim'
let g:vimtex_view_skim_reading_bar = 0
let g:vimtex_view_skim_sync = 0

" theme
autocmd VimEnter *.tex colorscheme peaksea

" disable gitgutter and indentlines
au VimEnter *.tex :GitGutterToggle
au VimEnter *.tex :IndentLinesToggle

" clean files on exit and key mapping
augroup vimtex_config
    au!
    au User VimtexEventQuit call vimtex#compiler#clean(0)
    au FileType tex nmap <buffer><silent> <leader>t <plug>(vimtex-toc-open)
    au FileType tex nmap <buffer><silent> <leader>v <plug>(vimtex-view)
augroup END

" Trigger configuration. You need to change this to something other than <tab> if you use one of the following:
" - https://github.com/Valloric/YouCompleteMe
" - https://github.com/nvim-lua/completion-nvim
let g:UltiSnipsSnippetsDir = "~/dotfiles/vim-settings/UltiSnips/"
let g:UltiSnipsExpandTrigger="<C-l>"
let g:UltiSnipsJumpForwardTrigger="<C-l>"
let g:UltiSnipsJumpBackwardTrigger="<C-z>"

" If you want :UltiSnipsEdit to split your window.
" let g:UltiSnipsEditSplit="vertical"

" disable auto renaming items to bullets
let g:vimtex_syntax_conceal_disable = 1
" set conceallevel=0
" set conceallevel=2
" let g:tex_conceal='abdgm'
" let g:tex_superscripts= "[0-9a-zA-W.,:;+-<>/()=]"
" let g:tex_subscripts= "[0-9aehijklmnoprstuvx,+-/().]"

" TOC settings
"au VimEnter *.tex :VimtexTocOpen
"au VimEnter *.tex :wincmd l

let g:vimtex_toc_config = {
      \ 'name' : 'TOC',
      \ 'layer_status' : {
          \ 'content': 1,
          \ 'label': 0,
          \ 'todo': 0,
          \ 'include': 0},
      \ 'resize' : 0,
      \ 'split_width' : 40,
      \ 'todo_sorted' : 0,
      \ 'show_help' : 0,
      \ 'show_numbers' : 1,
      \ 'hide_line_numbers' : 1,
      \ 'mode' : 2,
      \ 'indent_levels' : 1,
      \ 'fold_enable' : 0,
      \ 'refresh_always' : 0,
      \}
" refresh toc
augroup VimTeX
  autocmd!
  autocmd BufWritePost *.tex call vimtex#toc#refresh()
augroup END

let g:tex_flavor='latex'
let g:vimtex_fold_enabled = 0

" quick-fix window toggle
" https://learnvimscriptthehardway.stevelosh.com/chapters/38.html
let g:vimtex_quickfix_enabled = 1
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_quickfix_autoclose_after_keystrokes = 1
let g:vimtex_quickfix_ignore_filters = [
  \'Underfull \\hbox (badness [0-9]*) in paragraph at lines',
  \'Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in paragraph at lines',
  \'Underfull \\hbox (badness [0-9]*) in ',
  \'Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in ',
  \'Package hyperref Warning: Token not allowed in a PDF string',
  \'Package typearea Warning: Bad type area settings!',
  \'Marginpar on page',
  \'Split bibliography detected',
  \'Package biblatex Warning',
  \]

""" thesaurus
let g:tq_openoffice_en_file="/Users/uthpala/.vim_runtime/thesaurus/MyThes-1.0/th_en_US_new"
let g:tq_mthesaur_file="/Users/uthpala/.vim_runtime/thesaurus/mthesaur.txt"
let g:tq_enabled_backends=["openoffice_en", "mthesaur_txt", "datamuse_com",]
"set thesaurus+="/Users/uthpala/.vim_runtime/thesaurus/mthesaur.txt"

""" Turn on spell checking for .tex files
augroup texSpell
    autocmd!
    autocmd FileType tex setlocal spell
    autocmd BufRead,BufNewFile *.tex setlocal spell
augroup END

""" vim-pencil
let g:pencil#wrapModeDefault = 'soft'
augroup pencil
  autocmd!
  autocmd FileType tex call pencil#init()
augroup END

""" limelight
"autocmd VimEnter *.tex Limelight
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!
noremap <silent> <F5> :Limelight!!<CR>
"let g:limelight_paragraph_span = 1

""" vim-latexfmt
let g:latexfmt_no_join_any = [
            \ '\(\\)\@1<!%',
            \ '\begin',
            \ '\end',
            \ '\section',
            \ '\subsection',
            \ '\subsubsection',
            \ '\document',
            \ '\(\\)\@1<!\[',
            \ '\]',
            \ '\bigskip',
            \ '\smallskip',
            \ '\import',
            \ '\usepackage',
            \ '\hypersetup',
            \ '\newcommand',
            \ '\todo',
            \ '\include',
            \ '\singlespace',
            \ '\oneandhalfspace',
            \ '\newpage',
            \ '\phantomsection',
            \ '\addtocontents',
            \ '\listoffigures',
            \ '\listoftables',
            \ '\title',
            \ '\author',
            \ '\degreeName',
            \ '\paperType',
            \ '\defensemonth',
            \ '\gradmonth',
            \ '\gradyear',
            \ '\chair',
            \ '\keywords',
            \ '\newif',
            \ '\entryextra',
            \ '\graphicspath',
            \]
let g:latexfmt_no_join_next = [ '\\', '\centering', '\includegraphics' ]
let g:latexfmt_no_join_prev = [ '\item', '\label' ]
let g:latexfmt_verbatim_envs = [ 'table', 'equation', 'align', 'eqnarray', '\(\\)\@1<!\['  ]

map <silent> <leader>ik <Plug>latexfmt_format
autocmd BufWritePost *.tex :normal ,ik  " format paragraph on save

" YCM don't open autocomplete too frequently
let g:ycm_min_num_of_chars_for_completion = 1
let g:ycm_min_num_of_chars_for_completion_enabled = g:ycm_min_num_of_chars_for_completion
let g:ycm_min_num_of_chars_for_completion_disabled = 999

function FixLaTeXCompletion()
  if &ft == 'tex' && g:ycm_min_num_of_chars_for_completion != g:ycm_min_num_of_chars_for_completion_disabled
    let g:ycm_min_num_of_chars_for_completion = g:ycm_min_num_of_chars_for_completion_disabled
    normal! YcmRestartServer
  endif
  if &ft != 'tex' && g:ycm_min_num_of_chars_for_completion == g:ycm_min_num_of_chars_for_completion_disabled
    let g:ycm_min_num_of_chars_for_completion = g:ycm_min_num_of_chars_for_completion_enabled
    normal! YcmRestartServer
  endif
endfunction

augroup tex_ycm
  autocmd!

  " Connect VimTeX and YouCompleteMe.
  " Taken from |:help vimtex-complete-youcompleteme|.
  " autocmd VimEnter * let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme

    """ YCM cite
    " let g:ycm_semantic_triggers = {
    "         \ 'tex'  : ['{']
    "     \}
    if !exists('g:ycm_semantic_triggers')
        let g:ycm_semantic_triggers = {}
    endif
    au VimEnter *.tex let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme

  " Make YouCompleteMe *not* suggest identifiers in TeX documents.
  " References:
  " 1. |:help g:ycm_min_num_of_chars_for_completion|
  " 2. https://github.com/ycm-core/YouCompleteMe/issues/872
  autocmd BufEnter * call FixLaTeXCompletion()
augroup end

""" vim-litecorrect
augroup litecorrect
  autocmd!
  autocmd FileType tex call litecorrect#init()
augroup END


""" vim-textobj-sentence
set nocompatible
filetype plugin indent on
augroup textobj_sentence
  autocmd!
  autocmd FileType tex call textobj#sentence#init()
augroup END

" ---------- END OF LATEX SETTINGS ----------
