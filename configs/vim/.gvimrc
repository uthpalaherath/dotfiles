" theme
let g:gruvbox_contrast_dark = "medium"
colorscheme gruvbox
set transparency=0

" Default GUI font
set guifont=JetBrainsMono\ Nerd\ Font:h16

" Prepend conda base and ~/.local/bin so LSP servers and tools (fortls, ruff, ...) are found.
let $PATH = expand('~/.local/bin') . ':' . expand('~/miniforge3/bin') . ':' . $PATH

" coc.vim
let g:coc_node_path = '/Users/ukh/.nvm/versions/node/v22.20.0/bin/node'

" gitgutter colors
highlight clear SignColumn
highlight gitgutteradd ctermfg=green guifg=darkgreen
highlight gitgutterchange ctermfg=yellow guifg=darkyellow
highlight gitgutterdelete ctermfg=red guifg=darkred
highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

" ale linter signs
let g:ale_change_sign_column_color = 0
highlight ALEErrorSign guifg=darkred guibg=NONE
highlight ALEWarningSign guifg=darkyellow guibg=NONE
highlight ALEInfoSign   guifg=#ED6237 guibg=NONE
highlight ALEError guifg=#C30500 guibg=NONE
highlight ALEWarning guifg=#ED6237 guibg=NONE
highlight ALEInfo guifg=#ED6237 guibg=NONE

" coc draws its own diagnostic signs; re-link after colorscheme reset them
highlight link CocErrorSign ALEErrorSign
highlight link CocWarningSign ALEWarningSign
highlight link CocInfoSign ALEInfoSign
highlight link CocHintSign ALEInfoSign
