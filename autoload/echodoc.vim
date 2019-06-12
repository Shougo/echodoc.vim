"=============================================================================
" FILE: echodoc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" License: MIT license
"=============================================================================

" Variables
let s:echodoc_dicts = [ echodoc#default#get() ]
let s:is_enabled = 0
let s:echodoc_id = 1050
if exists('*nvim_create_namespace')
  let s:echodoc_id = nvim_create_namespace('echodoc.vim')
elseif exists('*nvim_buf_add_highlight')
  let s:echodoc_id = nvim_buf_add_highlight(0, 0, '', 0, 0, 0)
endif
if exists('*nvim_create_buf')
  let s:floating_buf = v:null
  let s:win = v:null
  let s:floating_buf = nvim_create_buf(v:false, v:true)
endif

let g:echodoc#type = get(g:,
      \ 'echodoc#type', 'echo')
let g:echodoc#highlight_identifier = get(g:,
      \ 'echodoc#highlight_identifier', 'Identifier')
let g:echodoc#highlight_arguments = get(g:,
      \ 'echodoc#highlight_arguments', 'Special')
let g:echodoc#highlight_trailing = get(g:,
      \ 'echodoc#highlight_trailing', 'Type')
let g:echodoc#events = get(g:,
      \ 'echodoc#events', ['CompleteDone'])

function! echodoc#enable() abort
  if &showmode && &cmdheight < 2 && echodoc#is_echo()
    " Increase the cmdheight so user can clearly see the error
    set cmdheight=2
    call s:print_error('Your cmdheight is too small. '
          \ .'You must increase ''cmdheight'' value or set noshowmode.')
  endif

  augroup echodoc
    autocmd!
    autocmd InsertEnter * call s:on_timer('InsertEnter')
    autocmd CursorMovedI * call s:on_timer('CursorMovedI')
    autocmd InsertLeave * call s:on_insert_leave()
  augroup END
  for event in g:echodoc#events
    if exists('##' . event)
      execute printf('autocmd echodoc %s * call s:on_event("%s")',
            \ event, event)
    endif
  endfor
  let s:is_enabled = 1
endfunction
function! echodoc#disable() abort
  augroup echodoc
    autocmd!
  augroup END
  let s:is_enabled = 0
endfunction
function! echodoc#is_enabled() abort
  return s:is_enabled
endfunction
function! echodoc#is_echo() abort
  return !echodoc#is_signature() && !echodoc#is_virtual() && !echodoc#is_floating()
endfunction
function! echodoc#is_signature() abort
  return g:echodoc#type ==# 'signature'
        \ && has('nvim') && get(g:, 'gonvim_running', 0)
endfunction
function! echodoc#is_virtual() abort
  return g:echodoc#type ==# 'virtual' && exists('*nvim_buf_set_virtual_text')
endfunction
function! echodoc#is_floating() abort
  return g:echodoc#type ==# 'floating' && exists('*nvim_open_win')
endfunction
function! echodoc#get(name) abort
  return get(filter(s:echodoc_dicts,
        \ 'v:val.name ==#' . string(a:name)), 0, {})
endfunction
function! echodoc#register(name, dict) abort
  " Unregister previous dict.
  call echodoc#unregister(a:name)

  call add(s:echodoc_dicts, a:dict)

  " Sort.
  call sort(s:echodoc_dicts, 's:compare')
endfunction
function! echodoc#unregister(name) abort
  call filter(s:echodoc_dicts, 'v:val.name !=#' . string(a:name))
endfunction

" Misc.
function! s:compare(a1, a2) abort
  return a:a1.rank - a:a2.rank
endfunction
function! s:context_filetype_enabled() abort
  if !exists('s:exists_context_filetype')
    try
      call context_filetype#version()
      let s:exists_context_filetype = 1
    catch
      let s:exists_context_filetype = 0
    endtry
  endif

  return s:exists_context_filetype
endfunction
function! s:print_error(msg) abort
  echohl Error | echomsg '[echodoc] '  . a:msg | echohl None
endfunction

" Autocmd events.
function! s:on_timer(event) abort
  if !has('timers')
    return s:on_event()
  endif

  if exists('s:_timer')
    call timer_stop(s:_timer)
  endif

  let s:_timer = timer_start(100, {-> s:on_event(a:event)})
endfunction
function! s:on_event(event) abort
  unlet! s:_timer

  let filetype = s:context_filetype_enabled() ?
        \ context_filetype#get_filetype(&filetype) : &l:filetype
  if filetype ==# ''
    let filetype = 'nothing'
  endif

  let completed_item = get(v:, 'completed_item', {})
  if empty(completed_item) && exists('v:event')
    let completed_item = get(v:event, 'completed_item', {})
  endif
  if filetype !=# '' && !empty(completed_item)
    call echodoc#default#make_cache(filetype, completed_item)
  endif

  let dicts = filter(copy(s:echodoc_dicts),
        \ "empty(get(v:val, 'filetypes', {}))
        \  || get(v:val.filetypes, filetype, 0)")

  let defaut_only = len(dicts) == 1

  if defaut_only && empty(echodoc#default#get_cache(filetype))
    return
  endif

  let cur_text = echodoc#util#get_func_text()

  " No function text was found
  if cur_text ==# '' && defaut_only
    return
  endif

  let echodoc = {}
  for doc_dict in dicts
    if doc_dict.name ==# 'default'
      let ret = doc_dict.search(cur_text, filetype)
    else
      let ret = doc_dict.search(cur_text)
    endif

    if !empty(ret)
      " Overwrite cached result
      let echodoc = ret
      break
    endif
  endfor

  if !empty(echodoc)
    let b:echodoc = echodoc
    call s:display(echodoc, filetype)
  elseif exists('b:echodoc')
    unlet b:echodoc
  endif
endfunction
" @vimlint(EVL103, 0, a:timer)
function! s:on_insert_leave() abort
  if echodoc#is_signature()
    call rpcnotify(0, 'Gui', 'signature_hide')
  endif
  if echodoc#is_floating()
    if s:win != v:null
      call nvim_win_close(s:win, v:false)
      let s:win = v:null
    endif
    call nvim_buf_clear_namespace(s:floating_buf, s:echodoc_id, 0, -1)
  endif
  if echodoc#is_virtual()
    call nvim_buf_clear_namespace(bufnr('%'), s:echodoc_id, 0, -1)
  endif
endfunction

function! s:display(echodoc, filetype) abort
  " Text check
  let text = ''
  for doc in a:echodoc
    let text .= doc.text
  endfor
  if matchstr(text, '^\s*$')
    return
  endif

  " Display
  if echodoc#is_signature()
    let parse = echodoc#util#parse_funcs(getline('.'), a:filetype)
    if empty(parse)
      return
    endif
    let col = -(col('.') - parse[-1].start + 1)
    let idx = 0
    let text = ''
    let line = (winline() <= 2) ? 3 : -1
    for doc in a:echodoc
      let text .= doc.text
      if has_key(doc, 'i')
        let idx = doc.i
      endif
    endfor
    call rpcnotify(0, 'Gui', 'signature_show', text, [line, col], idx)
    redraw!
  elseif echodoc#is_virtual()
    call nvim_buf_clear_namespace(bufnr('%'), s:echodoc_id, 0, -1)
    let chunks = map(copy(a:echodoc),
          \ "[v:val.text, get(v:val, 'highlight', 'Normal')]")
    call nvim_buf_set_virtual_text(
          \ bufnr('%'), s:echodoc_id, line('.') - 1, chunks, {})
  elseif echodoc#is_floating()
    let hunk = join(map(copy(a:echodoc), "v:val.text"), "")
    let window_width = strlen(hunk)

    let identifier_pos = match(getline('.'), a:echodoc[0].text)
    if identifier_pos != -1 " Identifier found in current line
      let cursor_pos = getpos('.')[2]
      " align the function signature text and the line text
      let identifier_pos =  cursor_pos - identifier_pos
    endif
    call nvim_buf_set_lines(s:floating_buf, 0, -1, v:true, [hunk])
    let opts = {'relative': 'cursor', 'width': window_width,
        \ 'height': 1, 'col': -identifier_pos + 1,
        \ 'row': 0, 'anchor': 'SW'}
    if s:win == v:null
      let s:win = nvim_open_win(s:floating_buf, 0, opts)

      call nvim_win_set_option(s:win, 'number', v:false)
      call nvim_win_set_option(s:win, 'relativenumber', v:false)
      call nvim_win_set_option(s:win, 'cursorline', v:false)
      call nvim_win_set_option(s:win, 'cursorcolumn', v:false)
      call nvim_win_set_option(s:win, 'colorcolumn', '')
      call nvim_win_set_option(s:win, 'conceallevel', 2)
      call nvim_win_set_option(s:win, 'signcolumn', "no")
      call nvim_win_set_option(s:win, 'winhl', 'Normal:EchoDocFloat')

      call nvim_buf_set_option(s:floating_buf, "buftype", "nofile")
      call nvim_buf_set_option(s:floating_buf, "bufhidden", "delete")

    else
      call nvim_win_set_config(s:win, opts)
    endif

    call nvim_buf_clear_namespace(s:floating_buf, s:echodoc_id, 0, -1)

    let last_chunk_index = 0
    for doc in a:echodoc
      let len_current_chunk = strlen(doc.text)
      if has_key(doc, 'highlight')
        call nvim_buf_add_highlight(s:floating_buf, s:echodoc_id, doc.highlight, 0,
              \ last_chunk_index, len_current_chunk+last_chunk_index)
      endif
      let last_chunk_index += len_current_chunk
    endfor
  else
    echo ''
    for doc in a:echodoc
      if has_key(doc, 'highlight')
        execute 'echohl' doc.highlight
        echon doc.text
        echohl None
      else
        echon doc.text
      endif
    endfor
  endif
endfunction
