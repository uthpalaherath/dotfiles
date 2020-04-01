colorscheme molokai
set transparency=5
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
highlight GitGutterAdd ctermfg=green guifg=darkgreen
highlight GitGutterChange ctermfg=yellow guifg=darkyellow
highlight GitGutterDelete ctermfg=red guifg=darkred
highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow
