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
" Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" Code completion
Plug 'dense-analysis/ale'
" Productivity metrics
Plug 'wakatime/vim-wakatime'
" color scheme
Plug 'altercation/vim-colors-solarized'
Plug 'frenzyexists/aquarium-vim', { 'branch': 'develop' }
Plug 'flazz/vim-colorschemes', { 'commit': 'fd8f122' }
Plug 'chriskempson/base16-vim', { 'commit': '7959654' }
call plug#end()
colors brogrammer
" Use ag (the silver searcher) with ctrlp
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif
