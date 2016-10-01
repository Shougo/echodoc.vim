"=============================================================================
" FILE: echodoc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

if exists('g:loaded_echodoc')
  finish
endif

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

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

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__
" vim: foldmethod=marker
