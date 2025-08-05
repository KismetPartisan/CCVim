syntax on
set number
set autoindent
" It might only be a problem with my setup,
" different mods & settings should be tested
ignorehold leftShift
inoremap <C-[> <esc>
" <C-t> might not work on some setups
inoremap <C-t> <C-o>>>
inoremap <C-d> <C-o><lt><lt>
inoremap <C-i> <space><space><space><space>
" Paste from the host clipboard
" Some computer implementations do not send paste on <C-S-v>, so <C-v> is
" preferred
nnoremap "<C-v>p a<C-S-v><esc>
noremap! <C-r><C-v> <C-S-v>
