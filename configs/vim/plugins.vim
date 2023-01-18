set nocompatible              " be iMproved, required
filetype off                  " required

call plug#begin('~/.vim/addons')
" File opener with fuzzy search.
Plug 'ctrlpvim/ctrlp.vim'
Plug 'imkmf/ctrlp-branches'
Plug 'hara/ctrlp-colorscheme'
Plug 'preservim/nerdcommenter'
Plug 'junegunn/fzf'
Plug 'tpope/vim-fugitive'
" Language-specific syntax highlighting
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
Plug 'prettier/vim-prettier', {'do': 'npm install'}
Plug 'haskell/haskell-mode'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" Code completion
Plug 'dense-analysis/ale'
" Productivity metrics
Plug 'wakatime/vim-wakatime'
call plug#end()

" Use ag (the silver searcher) with ctrlp
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif
