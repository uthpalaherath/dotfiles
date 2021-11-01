syntax enable
colorscheme molokai
"colorscheme gruvbox
set transparency=0
set guifont=Monaco:h15

" cursor options
highlight Cursor guifg=white guibg=steelblue
highlight iCursor guifg=white guibg=lightgray
set guicursor=n-v-c:block-Cursor
set guicursor+=i:ver100-iCursor
set guicursor+=n-v-c:blinkon0
set guicursor+=i:blinkwait1000

" gitgutter colors
highlight clear SignColumn
highlight gitgutteradd ctermfg=green guifg=darkgreen
highlight gitgutterchange ctermfg=yellow guifg=darkyellow
highlight gitgutterdelete ctermfg=red guifg=darkred
highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

let g:ale_change_sign_column_color = 0
highlight ALEErrorSign guifg=darkred guibg=NONE
highlight ALEWarningSign guifg=darkyellow guibg=NONE
highlight ALEInfoSign   guifg=#ED6237 guibg=NONE
highlight ALEError guifg=#C30500 guibg=NONE
highlight ALEWarning guifg=#ED6237 guibg=NONE
highlight ALEInfo guifg=#ED6237 guibg=NONE
