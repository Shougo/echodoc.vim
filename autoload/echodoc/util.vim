"=============================================================================
" FILE: autoload/echodoc/util.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
"          Tommy Allen <tommy@esdf.io>
" License: MIT license
"=============================================================================

" Returns a parsed stack of functions found in the text.  Each item in the
" stack contains a dict:
" - name: Function name.
" - start: Argument start position.
" - end: Argument end position.  -1 if the function is unclosed.
" - pos: The argument position.  1-indexed, 0 = no args, -1 = closed.
" - ppos: The function's position in the previous function in the stack.
" - args: A list of arguments.
function! echodoc#util#parse_funcs(text) abort
  if a:text == ''
    return []
  endif

  let quote_i = -1
  let stack = []
  let open_stack = []
  let comma = 0

  " Matching pairs will count as a single argument entry so that commas can be
  " skipped within them.  The open depth is tracked in each open stack item.
  " Parenthesis is an exception since it's used for functions and can have a
  " depth of 1.
  let pairs = '({[)}]'
  let l = len(a:text) - 1
  let i = -1

  while i < l
    let i += 1
    let c = a:text[i]

    if i > 0 && a:text[i - 1] == '\'
      continue
    endif

    if quote_i != -1
      " For languages that allow '''' ?
      " if c == "'" && a:text[i - 1] == c && i - quote_i > 1
      "   continue
      " endif
      if c == a:text[quote_i]
        let quote_i = -1
      endif
      continue
    endif

    if quote_i == -1 && (c == "'" || c == '"' || c == '`')
      " backtick (`) is not used alone in languages that I know of.
      let quote_i = i
      continue
    endif

    let prev = len(open_stack) ? open_stack[-1] : {'opens': [0, 0, 0]}
    let opened = prev.opens[0] + prev.opens[1] + prev.opens[2]

    let p = stridx(pairs, c)
    if p != -1
      let ci = p % 3
      if p == 3 && opened == 1 && prev.opens[0] == 1
        " Closing the function parenthesis
        if len(open_stack)
          let item = remove(open_stack, -1)
          let item.end = i - 1
          let item.pos = -1
          let item.opens[0] -= 1
          if comma <= i
            call add(item.args, a:text[comma :i - 1])
          endif
          let comma = item.i
        endif
      elseif p == 0
        " Opening parenthesis
        let func_i = match(a:text[:i - 1], '\S', comma)
        let func_name = matchstr(a:text[func_i :i - 1], '\k\+$')

        if func_i != -1 && func_i < i - 1 && func_name != ''
          let ppos = 0
          if len(open_stack)
            let ppos = open_stack[-1].pos
          endif

          if func_name != ''
            " Opening parenthesis that's preceded by a non-empty string.
            call add(stack, {
                  \ 'name': func_name,
                  \ 'i': func_i,
                  \ 'start': i + 1,
                  \ 'end': -1,
                  \ 'pos': 0,
                  \ 'ppos': ppos,
                  \ 'args': [],
                  \ 'opens': [1, 0, 0]
                  \ })
            call add(open_stack, stack[-1])

            " Function opening parenthesis marks the beginning of arguments.
            " let comma = i + 1
            let comma = i + 1
          endif
        else
          let prev.opens[0] += 1
        endif
      else
        let prev.opens[ci] += p > 2 ? -1 : 1
      endif
    elseif opened == 1 && prev.opens[0] == 1 && c == ','
      " Not nested in a pair.
      if len(open_stack) && comma <= i
        let open_stack[-1].pos += 1
        call add(open_stack[-1].args, a:text[comma :i - 1])
      endif
      let comma = i + 1
    endif
  endwhile

  if len(open_stack)
    let item = open_stack[-1]
    call add(item.args, a:text[comma :l])
    let item.pos += 1
  endif

  if len(stack) && stack[-1].opens[0] == 0
    let item = stack[-1]
    let item.trailing = matchstr(a:text, '\s*\zs\p*', item.end + 2)
  endif

  return stack
endfunction


function! echodoc#util#completion_signature(completion, maxlen) abort
  if empty(a:completion)
    return {}
  endif

  let info = matchstr(a:completion.info, '^\_s*\zs.*')

  if info == ''
    if a:completion.abbr =~# '^.\+('
      let info = a:completion.abbr
    else
      if a:completion.word =~# '^.\+(' || a:completion.kind == 'f'
        let info = a:completion.word
      endif
    endif
  endif

  let info = info[:a:maxlen]
  let stack = echodoc#util#parse_funcs(info)

  if empty(stack)
    return {}
  endif

  let comp = stack[0]
  let word = matchstr(a:completion.word, '\k\+')
  if comp.name != word
    " Completion 'word' is what actually completed, if the parsed name is
    " different, it's probably because 'info' is an abstract function
    " signature.  .e.g in Go:
    " completed: BoolVar(p *bool, name string, value bool, usage string)
    " info:      func(p *bool, name string, value bool, usage string)
    let comp.name = word
  endif
  return comp
endfunction
