"=============================================================================
" FILE: echodoc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Aug 2010
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
" Version: 0.1, for Vim 7.0
"=============================================================================

" Variables  "{{{
let s:echodoc_dicts = []
"}}}

function! echodoc#enable()"{{{
  augroup echodoc
    autocmd!
    autocmd CursorMovedI,CursorHold * call s:on_cursor_moved()
  augroup END
endfunction"}}}
function! echodoc#disable()"{{{
endfunction"}}}
function! echodoc#register(name, dict)"{{{
  " Unregister previous dict.
  call echodoc#unregister(a:name)
  
  call add(s:echodoc_dicts, a:dict)

  " Sort.
  call sort(s:echodoc_dicts, 's:compare')
endfunction"}}}
function! echodoc#unregister(name)"{{{
  call filter(s:echodoc_dicts, 'v:val.name !=#' . string(a:name))
endfunction"}}}

" Misc.
function! s:compare(a1, a2)  "{{{
  return a:a1.rank - a:a2.rank
endfunction"}}}
function! s:get_cur_text()  "{{{
  let l:pos = mode() ==# 'i' ? 2 : 1

  let l:cur_text = col('.') < l:pos ? '' : matchstr(getline('.'), '.*')[: col('.') - l:pos]
  return substitute(l:cur_text, '\h\w*$', '', '')
endfunction"}}}
function! s:neocomplcache_enabled()  "{{{
  return exists('neocomplcache#is_enabled') && neocomplcache#is_enabled()
endfunction"}}}

" Autocmd events.
function! s:on_cursor_moved()  "{{{
  let l:cur_text = s:get_cur_text()
  let l:filetype = s:neocomplcache_enabled() ? neocomplcache#get_context_filetype(1) : &filetype
  let l:echo_cnt = 0

  for l:doc_dict in s:echodoc_dicts
    if empty(l:doc_dict.filetypes) || has_key(l:doc_dict.filetypes, l:filetype)
      let l:ret = l:doc_dict.search(l:cur_text)

      if !empty(l:ret)
        echo ''
        for l:text in l:ret
          if has_key(l:text, 'highlight')
            execute 'echohl' l:text.highlight
            echon l:text.text
            echohl None
          else
            echon l:text.text
          endif
        endfor
        
        let l:echo_cnt += 1
        if l:echo_cnt >= &cmdheight
          break
        endif
      endif
    endif
  endfor
endfunction"}}}

" vim: foldmethod=marker
