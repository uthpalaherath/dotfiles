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
" author: Uthpala Herath

""" Plugin Manager
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim_runtime/my_plugins')

" Plugins list
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'whiteinge/diffconflicts'
Plug 'zivyangll/git-blame.vim'
Plug 'junkblocker/git-time-lapse'
Plug 'Yggdroot/indentLine'
Plug 'tomasr/molokai'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'preservim/tagbar'
Plug 'djoshea/vim-autoread'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'szw/vim-maximizer'
Plug 'jpalardy/vim-slime', { 'for': 'python' }
Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }
Plug 'pixelneo/vim-python-docstring'
Plug 'kshenoy/vim-signature'
Plug 'psliwka/vim-smoothie'
Plug 'ZSaberLv0/ZFVimDirDiff'
Plug 'ZSaberLv0/ZFVimJob'
Plug 'ZSaberLv0/ZFVimIgnore'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'adah1972/vim-copy-as-rtf'
"Plug 'mhinz/vim-startify'

" Latex plugins
Plug 'cocopon/iceberg.vim'
Plug 'junegunn/limelight.vim'
Plug 'Ron89/thesaurus_query.vim'
Plug 'dahu/vim-fanfingtastic'
Plug 'engeljh/vim-latexfmt'
Plug 'preservim/vim-litecorrect'
Plug 'preservim/vim-pencil'
Plug 'kana/vim-textobj-user'
Plug 'preservim/vim-textobj-sentence'
Plug 'lervag/vimtex'
Plug 'honza/writer.vim'
Plug 'anufrievroman/vim-angry-reviewer'
call plug#end()

:set encoding=utf-8
:set fileencoding=utf-8
:set display=lastline    " Show as much as possible of a wrapped last line, not just @.
:set number
au FileType javascript setl nofen

""" Toggle line wrap
map <F9> :set wrap!<CR>

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
let g:indentLine_char = '┊'

""" ALE
let g:ale_virtualtext_cursor = 0
let g:ale_disable_lsp = 1
let g:ale_linters = {'python':['flake8', 'pydocstyle'], 'tex':['proselint', 'writegood', 'vale']}
let g:ale_fixers = {'*':['remove_trailing_lines', 'trim_whitespace'], 'python':['black']}
let g:ale_fix_on_save = 1
let g:ale_lint_on_enter = 0 """ Don't lint when opening a file
let g:ale_sign_error = '•'
let g:ale_sign_warning = '.'
autocmd VimEnter * :let g:ale_change_sign_column_color = 0
autocmd VimEnter * :highlight! ALEErrorSign ctermfg=9 ctermbg=NONE guifg=#ff0000 guibg=NONE
autocmd VimEnter * :highlight! ALEWarningSign ctermfg=11 ctermbg=NONE guifg=#ffff00 guibg=NONE
autocmd VimEnter * :highlight! ALEInfoSign   ctermfg=14 ctermbg=NONE guifg=#00ffff guibg=NONE
autocmd VimEnter * :highlight! ALEError ctermfg=9 ctermbg=NONE guifg=#ff0000 guibg=NONE
autocmd VimEnter * :highlight! ALEWarning ctermfg=11 ctermbg=NONE guifg=#ffff00 guibg=NONE
autocmd VimEnter * :highlight! ALEInfo   ctermfg=14 ctermbg=NONE guifg=#00ffff guibg=NONE

" flake8 file
"let g:syntastic_python_flake8_config_file='~/dotfiles/vim-settings/.flake8'

" disable ALE for tex files
autocmd BufEnter *.tex ALEDisable

""" toggle line numbers, indentLines and gitgutter
noremap <silent> <F3> :set invnumber invrelativenumber \| IndentLinesToggle \| :GitGutterToggle <CR>

""" Remapping keys
:imap jk <ESC>`^

""" Tab settings
set tabstop=4           """ width that a <TAB> character displays as
set expandtab           " convert <TAB> key-presses to spaces
set shiftwidth=4        " number of spaces to use for each step of (auto)indent
set softtabstop=4       " backspace after pressing <TAB> will remove up to this many spaces
set autoindent          " copy indent from current line when starting a new line
set smartindent         " even better autoindent (e.g. add indent after '{')'}')

""" colors
syntax enable
filetype plugin indent on
set t_Co=256
colorscheme molokai
highlight clear SignColumn
highlight LineNr ctermbg=235
highlight LineNr ctermfg=241

""" ZRDirDiff settings
let g:ZFDirDiff_ignoreEmptyDir = 1
let g:ZFDirDiff_ignoreSpace = 1
let g:ZFIgnoreOption_ZFDirDiff = {
            \   'bin' : 1,
            \   'media' : 1,
            \   'common' : 1,
            \ }

" Define function to restore settings
function! s:RestoreDefaultSettings()
    " Re-enable syntax highlighting
    syntax enable

    " Reapply custom highlight settings
    highlight clear SignColumn
    highlight LineNr ctermbg=235
    highlight LineNr ctermfg=241

    " Reapply GitGutter highlight settings
    highlight GitGutterAdd           ctermfg=2   guifg=#008000
    highlight GitGutterChange        ctermfg=3   guifg=#808000
    highlight GitGutterDelete        ctermfg=1   guifg=#800000
    highlight GitGutterChangeDelete  ctermfg=4   guifg=#000080

    " Reapply gitgutter settings
    let g:gitgutter_override_sign_column_highlight = 0
    let g:gitgutter_highlight_linenrs = 1
    let g:gitgutter_preview_win_floating = 0
    let g:gitgutter_diff_args = '-w'

    " Reset ALE settings
    let g:ale_change_sign_column_color = 0
    highlight ALEErrorSign ctermfg=9 ctermbg=NONE guifg=#ff0000 guibg=NONE
    highlight ALEWarningSign ctermfg=11 ctermbg=NONE guifg=#ffff00 guibg=NONE
    highlight ALEInfoSign   ctermfg=14 ctermbg=NONE guifg=#00ffff guibg=NONE
    highlight ALEError ctermfg=9 ctermbg=NONE guifg=#ff0000 guibg=NONE
    highlight ALEWarning ctermfg=11 ctermbg=NONE guifg=#ffff00 guibg=NONE
    highlight ALEInfo   ctermfg=14 ctermbg=NONE guifg=#00ffff guibg=NONE

    " Reset nerdtree colors
    highlight Directory guifg=#FF0000 ctermfg=blue

    " Reset the indentLine plugin
    if exists(':IndentLinesReset')
        execute 'IndentLinesReset'
    else
        execute 'IndentLinesToggle'
        execute 'IndentLinesToggle'
    endif

    " Reapply indentLine settings
    let g:indentLine_char = '┊'

    " Restore line number settings
    set number
    set relativenumber
endfunction

" Function to update colorscheme based on 'diff' option
function! s:UpdateDiffColors()
    if &diff
        let g:gruvbox_contrast_dark = "soft"
        colorscheme gruvbox
    else
        colorscheme molokai
        call s:RestoreDefaultSettings()
    endif
endfunction

" Apply gruvbox colorscheme if Vim starts in diff mode
if &diff
    call s:UpdateDiffColors()
endif

" Autocommand group for handling 'diff' option changes
augroup MyDiffColors
    autocmd!
    autocmd OptionSet diff call s:UpdateDiffColors()
augroup END

" Autocommand for reapplying settings when molokai is loaded
augroup MyColorscheme
    autocmd!
    autocmd ColorScheme molokai call s:RestoreDefaultSettings()
augroup END

" Settings for the dirdff.sh script
augroup ZFDirDiffGruvbox
  autocmd!
  autocmd TabEnter * if exists('g:ZFDirDiff_tabOpened') | let g:gruvbox_contrast_dark = "soft" | colorscheme gruvbox | endif
augroup END

" ---------- End of ZRDirDiff settings ----------

" Use new regular expression engine
set re=0
set redrawtime=10000

""" NERDtree configuration
let NERDTreeShowLineNumbers = 0
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let NERDTreeQuitOnOpen = 1
let NERDTreeGitStatusConcealBrackets = 0 " default: 0
let NERDTreeGitStatusShowClean = 0 " default: 0
let NERDTreeNaturalSort = 1

" function! StartUp()
"     if 0 == argc()
"         NERDTree
"     end
" endfunction
" autocmd VimEnter * call StartUp()
" autocmd VimEnter * wincmd h
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
hi Directory guifg=#FF0000 ctermfg=blue
let NERDTreeIgnore=['\.o$', '\.pyc$', '\.pdf$', '\.so$', '\.gz$' ]

" Reveal current file
function! IsNERDTreeOpen()
  return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction

" Create a function that ensures NERDTree is open and highlights the current file
function! HighlightInNERDTree() abort
  " If NERDTree isn't open, open it
  if !IsNERDTreeOpen()
    NERDTree
  endif

  " Highlight the current file iff it's modifiable, non-empty, and we're not in diff mode
  if &modifiable && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
    " Return to original window
    wincmd p
  endif
endfunction

" Map <leader>n to call the highlight function
nnoremap <leader>n :call HighlightInNERDTree()<CR>

""" copy to buffer (Only works on Mac)
" map <C-c> y:e ~/clipboard<CR>P:w! !pbcopy<CR><CR>:bdelete!<CR>

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

""" gitgutter
let g:gitgutter_enabled = 1
" Colors
let g:gitgutter_override_sign_column_highlight = 0
highlight GitGutterAdd ctermfg=2 guifg=#008000
highlight GitGutterChange ctermfg=3 guifg=#808000
highlight GitGutterDelete ctermfg=1 guifg=#800000
highlight GitGutterChangeDelete ctermfg=4 guifg=#000080
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)
let g:gitgutter_highlight_linenrs = 1
let g:gitgutter_preview_win_floating = 0
let g:gitgutter_diff_args = '-w'

""" split screen shortcuts
nnoremap <C-W>- :new<CR>
nnoremap <C-W>\ :vnew<CR>

""" visual marks
nnoremap <leader>m :SignatureRefresh<CR>

""" changesPlugin
let g:changes_use_icons=0

""" Fortran
":let b:fortran_fixed_source=0
":set syntax=fortran
let fortran_free_source=1
let fortran_do_enddo=1
let fortran_more_precise=1

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
nnoremap <Leader>S :vert term <CR> py3 <CR> ipython --matplotlib<CR> <c-w><c-p> :SlimeConfig <CR>
nnoremap <Leader>s :term <CR> py3 <CR> ipython --matplotlib<CR> <c-w><c-p> :SlimeConfig <CR>

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
" Note: conflicts with vimdiff
" nnoremap [c :IPythonCellPrevCell<CR>
" nnoremap ]c :IPythonCellNextCell<CR>

" map <Leader>h to send the current line or current selection to IPython
nmap <Leader>h <Plug>SlimeLineSend
xmap <Leader>h <Plug>SlimeRegionSend

" map <Leader>p to run the previous command
"nnoremap <Leader>p :IPythonCellPrevCommand<CR>

" map <Leader>Q to restart ipython
nnoremap <Leader>qq :IPythonCellRestart<CR>

" map <Leader> q to reset variables
" nnoremap <Leader>q :SlimeSend1 %reset -f<CR>

" map <Leader>d to start debug mode
"nnoremap <Leader>d :SlimeSend1 %debug<CR>

" map <Leader>q to exit debug mode or IPython
"nnoremap <Leader>q :SlimeSend1 exit<CR>

" map terminal scroll to Ctrl+b
tnoremap <c-b> <c-\><c-n>

""" Startify
" let g:startify_session_persistence = 1
" let g:startify_lists = [
"       \ { 'type': 'sessions',  'header': ['   Sessions']       },
"       \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
"       \ ]
" let g:startify_bookmarks = [ '~/.vim_runtime/my_configs.vim' ]

""" vim-maximizer
let g:maximizer_default_mapping_key = '<C-W>z'
nnoremap <silent><C-W>z :MaximizerToggle<CR>
vnoremap <silent><C-W>z :MaximizerToggle<CR>gv
inoremap <silent><C-W>z <C-o>:MaximizerToggle<CR>

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
" Auto generate tags file on write of files
" autocmd BufWritePost *.c,*.h,*.f90,*.F,*.F90 silent! !ctags . &

""" tagbar
nmap <F8> :TagbarToggle<CR>
let g:tagbar_sort = 0

" Open the definition in a new tab
:nnoremap <silent><Leader><C-]> <C-w><C-]><C-w>T

" Open the definition in a vertical split
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

""" vim-diff ignore whitespace
set diffopt+=iwhiteall,filler
set diffexpr=""

""" coc-vim
" ~/.vim/coc-settings.json
"
"{
"  "diagnostic.displayByAle": true,
"  "coc.preferences.snippets.enable": true,
"  "suggest.snippetIndicator": "",
"  "suggest.noselect": true,

"  "languageserver": {
"     "fortran": {
"       "command": "fortls",
"       "filetypes": ["fortran"],
"       "rootPatterns": [".fortls", ".git/"]
"      }
"    }
"}

" disable warning
let g:coc_disable_startup_warning = 1

" Install extensions
let g:coc_global_extensions = ['coc-snippets', 'coc-clangd', 'coc-python']

" coc-snippets
" Snippets are stored in ~/.config/coc/ultisnips
imap <C-l> <Plug>(coc-snippets-expand-jump)
let g:coc_snippet_prev = '<c-k>'
vmap <C-j> <Plug>(coc-snippets-select)

" Customize colors
:highlight CocFloating ctermbg=238 guibg=#444444
:highlight CocFloating ctermfg=Gray guifg=Gray
:highlight CocMenuSel ctermbg=240 guibg=#585858

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

""" Count search instances
autocmd VimEnter * set shortmess-=S

""" Ack.vim
" Use ripgrep for searching
" Options include:
" --vimgrep -> Needed to parse the rg response properly for ack.vim
" --type-not sql -> Avoid huge sql file dumps as it slows down the search
" --smart-case -> Search case insensitive if all lowercase pattern, Search case sensitively otherwise
" --follow -> Follow symlinks
" --hidden -> Search hidden files
let g:ackprg = 'rg --vimgrep --type-not sql --smart-case --follow --hidden -g "!{node_modules,.git}"'
let g:repprg = 'rg --vimgrep --type-not sql --smart-case --follow --hidden -g "!{node_modules,.git}"'

" Auto close the Quickfix list after pressing '<enter>' on a list item
let g:ack_autoclose = 0

" Any empty ack search will search for the work the cursor is on
let g:ack_use_cword_for_empty_search = 1

" Don't jump to first match
cnoreabbrev Ack Ack!

""" FZF
let $FZF_DEFAULT_COMMAND='rg --files --type-not sql --smart-case --follow --hidden -g "!{node_modules,.git}"'
let g:ctrlp_map = ''
nnoremap <silent> <C-f> :Files<CR>
nnoremap <silent> <Leader>f :RgBuf<CR>

" Rg without file names in search results
command! -bang -nargs=* RgBuf call
  \ fzf#vim#grep("rg --line-number --no-heading --color=always --smart-case --follow --hidden -g '!{node_modules,.git}' "
  \ .shellescape(<q-args>), 1, fzf#vim#with_preview({'options': '--delimiter : --nth 3..'}), <bang>0)

" Rg with arguments allowed
command! -bang -nargs=* Rg call HandleRgCommand(<q-args>, <bang>0)
function! HandleRgCommand(args, bang)
    if a:args == ''
        echo "USAGE: Rg PATTERN [OPTIONS] [PATH]"
    else
        call fzf#vim#grep("rg --line-number --no-heading --color=always --smart-case --follow --hidden -g '!{node_modules,.git}' "
        \ . a:args, 1, fzf#vim#with_preview({'options': '--delimiter : --nth 3..'}), a:bang)
    endif
endfunction

" Rg word under cursor
nnoremap <silent> <leader>* :RgBuf <C-R><C-W><CR>

" Search only within current open buffer
command! -bang -nargs=* BLines
    \ call fzf#vim#grep(
    \   'rg --with-filename --line-number --no-heading --smart-case --color=always . '.fnameescape(expand('%:p')), 1,
    \   fzf#vim#with_preview({'options': '--layout reverse --keep-right --delimiter : --nth 3.. --preview "bat -p --color always {}"'}, 'right:60%' ))
" nnoremap <leader>f :BLines<Cr>

" Command history
nnoremap <silent> <leader>q :call fzf#vim#command_history({'sink': 'e', 'window': 'botright 20new', 'options': '--no-preview'})<CR>

""" github-copilot
"let g:copilot_assume_mapped = v:true
imap <silent><script><expr> <C-e> copilot#Accept('\<CR>')
let g:copilot_no_tab_map = v:true

""" git-blame
nnoremap <Leader>b :<C-u>call gitblame#echo()<CR>

""" git-time-lapse
" :GitTimeLapse
" nmap <Leader>gt <Plug>(git-time-lapse)

""" Disable concealing in files
let g:vim_json_conceal=0
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0

""" ---------- LATEX SETTINGS ----------

" turn off line numbers for tex files
autocmd filetype tex setlocal nonumber norelativenumber

" Only enable vimtex if latexmk is installed
if !executable('latexmk')
  let g:vimtex_compiler_enabled = 0
endif

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
"autocmd VimEnter *.tex colorscheme peaksea
autocmd VimEnter *.tex colorscheme iceberg
autocmd VimEnter *.tex syntax enable

augroup tex_syntax
  au!
  autocmd BufNewFile,BufRead *.tex syntax enable
augroup END

" disable gitgutter and indentlines
au VimEnter *.tex :GitGutterToggle
au VimEnter *.tex :IndentLinesToggle

" clean files on exit and key mapping
augroup vimtex_config
    au!
    au User VimtexEventQuit call vimtex#compiler#clean(0)
    "au User VimtexEventQuit call vimtex#latexmk#clean(0)
    au FileType tex nmap <buffer><silent> <leader>t <plug>(vimtex-toc-open)
    au FileType tex nmap <buffer><silent> <leader>v <plug>(vimtex-view)
augroup END

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
noremap <silent> <F6> :Limelight!!<CR>
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
            \ '\noindent',
            \]
let g:latexfmt_no_join_next = [ '\\', '\centering', '\includegraphics' ]
let g:latexfmt_no_join_prev = [ '\item', '\label' ]
let g:latexfmt_verbatim_envs = [ 'table', 'equation', 'align', 'eqnarray', '\(\\)\@1<!\['  ]

map <silent> <leader>ik <Plug>latexfmt_format
autocmd BufWritePost *.tex :normal ,ik  " format paragraph on save

""" vim-litecorrect
augroup litecorrect
  autocmd!
  autocmd FileType tex call litecorrect#init()
augroup END

""" vim-textobj-sentence
set nocompatible
augroup textobj_sentence
  autocmd!
  autocmd FileType tex call textobj#sentence#init()
augroup END

""" Angry Reviewer
let g:AngryReviewerEnglish = 'american'

" ---------- END OF LATEX SETTINGS ----------
