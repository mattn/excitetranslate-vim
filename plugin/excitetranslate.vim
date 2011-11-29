" vim:set ts=8 sts=2 sw=2 tw=0:
"
" excitetranslate.vim - Translate between English and Japanese using Excite
"
" Maintainer:	MURAOKA Taro <koron@tka.att.ne.jp>
" Author:	Yasuhiro Matsumoto <mattn_jp@hotmail.com>
" Last Change:	29-Nov-2011.

if !exists('g:excitetranslate_options')
  let g:excitetranslate_options = ["register","buffer"]
endif

let s:endpoint = 'http://www.excite.co.jp/world/english/'

function! s:CheckEorJ(word)
  let all = strlen(a:word)
  let eng = strlen(substitute(a:word, '[^\t -~]', '', 'g'))
  return eng * 2 < all ? 'JAEN' : 'ENJA'
endfunction

function! ExciteTranslate(word, ...)
  let mode = a:0 >= 2 ? a:2 : s:CheckEorJ(a:word)
  let @a= mode
  let res = http#post(s:endpoint, {"before": a:word, "wb_lp": mode})
  let dom = html#parse(iconv(res.content, "utf-8", &encoding))
  let after = dom.find('textarea', {"id": "after"})
  return substitute(after.value(), "\x08", '', '')
endfunction

function! ExciteTranslateRange() range
  " Concatenate input string.
  let curline = a:firstline
  let strline = ''
  while curline <= a:lastline
    let tmpline = substitute(getline(curline), '^\s\+\|\s\+$', '', 'g')
    if tmpline=~ '\m^\a' && strline =~ '\m\a$'
      let strline = strline .' '. tmpline
    else
      let strline = strline . tmpline
    endif
    let curline = curline + 1
  endwhile
  " Do translate.
  let jstr = ExciteTranslate(strline)
  " Put to buffer.
  if index(g:excitetranslate_options, 'buffer') != -1
    " Open or go result buffer.
    let bufname = '==Translate== Excite'
    let winnr = bufwinnr(bufname)
    if winnr < 1
      execute 'below new '.escape(bufname, ' ')
    else
      if winnr != winnr()
	execute winnr.'wincmd w'
      endif
    endif
    setlocal buftype=nofile bufhidden=hide noswapfile wrap ft=
    " Append translated string.
    if line('$') == 1 && getline('$').'X' ==# 'X'
      call setline(1, jstr)
    else
      call append(line('$'), '--------')
      call append(line('$'), jstr)
    endif
    normal! Gzt
  endif
  " Put to unnamed register.
  if index(g:excitetranslate_options, 'register') != -1
    let @" = jstr
  endif
endfunction

command! -nargs=0 -range ExciteTranslate <line1>,<line2>call ExciteTranslateRange()
