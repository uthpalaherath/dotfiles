" theme
let g:gruvbox_contrast_dark = "medium"
colorscheme gruvbox
set transparency=0
autocmd VimEnter *.tex WriterToggle

" Default GUI font for everything else
set guifont=Monaco:h15

" Use Menlo only for Markdown buffers
augroup MarkdownFont
  autocmd!
  autocmd FileType markdown set guifont=Menlo:h15
augroup END

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
