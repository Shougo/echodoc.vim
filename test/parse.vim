" set verbose=1
scriptencoding utf8

let s:assert = themis#helper('assert')
let s:suite = themis#suite('parse')

function! s:suite.parse_funcs() abort
  call s:assert.not_equals(echodoc#util#parse_funcs(
        \ 'void main(int argc)'), [])
  call s:assert.not_equals(echodoc#util#parse_funcs(
        \ 'int32_t get (*)(void *const, const size_t)'), [])
endfunction
