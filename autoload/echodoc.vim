"=============================================================================
" FILE: echodoc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables  "{{{
" Default dict. "{{{
let s:default = {
      \ 'name' : 'default',
      \ 'rank' : 10,
      \ }
" @vimlint(EVL102, 1, v:completed_item)
function! s:default.search(cur_text) abort "{{{
  if !exists('v:completed_item') || empty(v:completed_item)
    return []
  endif

  let item = v:completed_item

  let abbr = (item.abbr != '') ? item.abbr : item.word
  if len(item.menu) > 5
    " Combine menu.
    let abbr .= ' ' . item.menu
  endif

  if item.info != ''
    let abbr = split(item.info, '\n\|\\n')[0]
  endif

  " Skip
  if len(abbr) < len(item.word) + 2
    return []
  endif

  let ret = []

  let match = stridx(abbr, item.word)
  if match < 0
    call add(ret, { 'text' : abbr })
  else
    call add(ret, { 'text' : item.word, 'highlight' : 'Identifier' })
    call add(ret, { 'text' : abbr[match+len(item.word) :] })
  endif

  return ret
endfunction"}}}
" @vimlint(EVL102, 0, v:completed_item)
"}}}

let s:echodoc_dicts = [ s:default ]
let s:is_enabled = 0
"}}}

function! echodoc#enable() abort "{{{
  if &showmode && &cmdheight < 2
    " Increase the cmdheight so user can clearly see the error
    set cmdheight=2
    call s:print_error('Your cmdheight is too small. '
          \ .'You must increase ''cmdheight'' value or set noshowmode.')
  endif

  augroup echodoc
    autocmd!
    autocmd CursorMovedI * call s:on_cursor_moved()
  augroup END
  let s:is_enabled = 1
endfunction"}}}
function! echodoc#disable() abort "{{{
  augroup echodoc
    autocmd!
  augroup END
  let s:is_enabled = 0
endfunction"}}}
function! echodoc#is_enabled() abort "{{{
  return s:is_enabled
endfunction"}}}
function! echodoc#get(name) abort "{{{
  return get(filter(s:echodoc_dicts,
        \ 'v:val.name ==#' . string(a:name)), 0, {})
endfunction"}}}
function! echodoc#register(name, dict) abort "{{{
  " Unregister previous dict.
  call echodoc#unregister(a:name)

  call add(s:echodoc_dicts, a:dict)

  " Sort.
  call sort(s:echodoc_dicts, 's:compare')
endfunction"}}}
function! echodoc#unregister(name) abort "{{{
  call filter(s:echodoc_dicts, 'v:val.name !=#' . string(a:name))
endfunction"}}}

" Misc.
function! s:compare(a1, a2) abort  "{{{
  return a:a1.rank - a:a2.rank
endfunction"}}}
function! s:get_cur_text() abort  "{{{
  let cur_text = matchstr(getline('.'),
        \ printf('^.*\%%%dc%s', col('.'), (mode() ==# 'i' ? '' : '.')))
  return cur_text
endfunction"}}}
function! s:context_filetype_enabled() abort  "{{{
  if !exists('s:exists_context_filetype')
    try
      call context_filetype#version()
      let s:exists_context_filetype = 1
    catch
      let s:exists_context_filetype = 0
    endtry
  endif

  return s:exists_context_filetype
endfunction"}}}
function! s:print_error(msg) abort  "{{{
  echohl Error | echomsg '[echodoc] '  . a:msg | echohl None
endfunction"}}}

" Autocmd events.
function! s:on_cursor_moved() abort  "{{{
  let cur_text = s:get_cur_text()
  let filetype = s:context_filetype_enabled() ?
        \ context_filetype#get_filetype(&filetype) : &l:filetype

  if !exists('b:echodoc')
    let b:echodoc = []
  endif

  let echodoc = b:echodoc
  for doc_dict in s:echodoc_dicts
    if !empty(get(doc_dict, 'filetypes', []))
          \ && !has_key(doc_dict.filetypes, filetype)
      continue
    endif

    let ret = doc_dict.search(cur_text)

    if !empty(ret)
      " Overwrite cached result
      let b:echodoc = ret
      let echodoc = ret
      break
    endif
  endfor

  echo ''
  for text in echodoc
    if has_key(text, 'highlight')
      execute 'echohl' text.highlight
      echon text.text
      echohl None
    else
      echon text.text
    endif
  endfor
endfunction"}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__
" vim: foldmethod=marker
