"=============================================================================
" FILE: echodoc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" License: MIT license
"=============================================================================

if exists('g:loaded_echodoc')
  finish
endif

" Global options definition. "{{{
if exists('g:echodoc_enable_at_startup') && g:echodoc_enable_at_startup
  " Enable startup.
  augroup echodoc
    autocmd!
    autocmd InsertEnter * call echodoc#enable()
  augroup END
endif"}}}
"}}}

command! EchoDocEnable call echodoc#enable()
command! EchoDocDisable call echodoc#disable()

let g:loaded_echodoc = 1

" __END__
" vim: foldmethod=marker
