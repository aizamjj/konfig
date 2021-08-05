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
" Language-specific syntax highlighting
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
" Auto close chars
Plug 'cohama/lexima.vim'
" Code completion
Plug 'valloric/youcompleteme'
call plug#end()
