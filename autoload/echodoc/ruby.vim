"=============================================================================
" FILE: autoload/echodoc/ruby.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" License: MIT license
"=============================================================================

function! echodoc#ruby#get() abort
  return s:doc_dict
endfunction

let s:doc_dict = {
      \ 'name' : 'ruby',
      \ 'rank' : 10,
      \ 'filetypes' : { 'ruby' : 1 },
      \ }
function! s:doc_dict.search(cur_text) abort
  if empty(get(v:, 'completed_item', {})) || !executable('ri')
    return []
  endif

  let id = matchstr(v:completed_item.menu, '\S\+$')
  if id == ''
    return []
  endif
  let doc = matchstr(system('ri ' . id), '\n-\+\n\zs.\{-}\ze\n')
  if doc == ''
    return []
  endif

  return [{ 'text' : id, 'highlight' : g:echodoc#highlight_identifier },
        \ {'text': doc}]
endfunction
