set shiftwidth=4
set tabstop=4
set softtabstop=4
set smartindent
set expandtab

set nu
set ff=unix
syntax enable
set hlsearch
hi Search ctermbg=White
hi Search ctermfg=Red

" search the selected text by pressing //
vnoremap // y/<C-R>"<CR> 

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %
