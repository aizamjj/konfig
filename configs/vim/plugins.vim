set nocompatible              " be iMproved, required
filetype off                  " required


call plug#begin('~/.vim/addons')
" File opener with fuzzy search.
Plug 'ctrlpvim/ctrlp.vim'
Plug 'imkmf/ctrlp-branches'
Plug 'hara/ctrlp-colorscheme'
Plug 'preservim/nerdtree'
Plug 'mileszs/ack.vim'
Plug 'junegunn/fzf'
Plug 'tpope/vim-fugitive'
" Language-specific syntax highlighting
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
" Auto close chars
Plug 'cohama/lexima.vim'
" Code completion
Plug 'valloric/youcompleteme'
Plug 'sbdchd/neoformat'
call plug#end()

" Use ag (the silver searcher) with ctrlp
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif
