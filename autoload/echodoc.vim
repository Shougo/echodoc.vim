"=============================================================================
" FILE: echodoc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables  "{{{
let s:max_parse_len = 1000
let s:complete_cache = {}

" Default dict. "{{{
let s:default = {
      \ 'name' : 'default',
      \ 'rank' : 10,
      \ }

" @vimlint(EVL102, 1, v:completed_item)
function! s:default.search(cur_text, filetype) abort "{{{
  if a:filetype == ''
    return []
  endif

  if !has_key(s:complete_cache, a:filetype)
    let s:complete_cache[a:filetype] = {}
  endif

  let cache = s:complete_cache[a:filetype]
  let comp = {}

  if !empty(v:completed_item)
    let v_comp = echodoc#util#completion_signature(v:completed_item, s:max_parse_len)
    if !empty(v_comp)
      if a:filetype == 'vim'
        let args = []
        for i in range(len(v_comp.args))
          for a in split(substitute(v_comp.args[i], '\[, ', ',[', 'g'), ',')
            call add(args, matchstr(a, '\s*\zs.\{-}\ze\s*$'))
          endfor
        endfor

        let v_comp.args = args
      endif

      let cache[v_comp.name] = v_comp
    endif
  endif

  for comp in reverse(echodoc#util#parse_funcs(a:cur_text))
    if comp.end == -1
      break
    endif
  endfor

  if empty(comp) || !has_key(cache, comp.name)
    return []
  endif

  let v_comp = cache[comp.name]
  let ret = [{'text': v_comp.name, 'highlight': 'Identifier'}, {'text': '('}]
  let l = max([comp.pos, len(v_comp.args)])

  for i in range(l)
    let item = {'text': '#'.i}

    if i < len(v_comp.args)
      let arg = v_comp.args[i]
      let item.text = matchstr(arg, '^\_s*\zs.\{-}\ze\_s*$')
    endif

    if i == comp.pos - 1 || (i == 0 && comp.pos == 0)
      let item.highlight = 'Special'
      let item.i = i
    endif

    call add(ret, item)

    if i != l - 1
      call add(ret, {'text': ', '})
    endif
  endfor

  call add(ret, {'text': ')'})

  if has_key(v_comp, 'trailing') && !empty(v_comp.trailing)
    call add(ret, {'text': ' -> '.v_comp.trailing})
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
    autocmd CompleteDone,CursorMovedI * call s:on_cursor_moved()
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
  if !has('timers')
    return s:_on_cursor_moved(0)
  endif

  if exists('s:_timer')
    call timer_stop(s:_timer)
  endif

  let s:_timer = timer_start(100, function('s:_on_cursor_moved'))
endfunction"}}}
" @vimlint(EVL103, 1, a:timer)
function! s:_on_cursor_moved(timer) abort  "{{{
  unlet! s:_timer
  let cur_text = echodoc#util#get_func_text()
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

    if doc_dict.name == 'default'
      let ret = doc_dict.search(cur_text, filetype)
    else
      let ret = doc_dict.search(cur_text)
    endif

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
" @vimlint(EVL103, 0, a:timer)

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__
" vim: foldmethod=marker
