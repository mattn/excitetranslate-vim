" vim:set ts=8 sts=2 sw=2 tw=0:
"
" excitetranslate.vim - Translate between English and Japanese using Excite
"
" Maintainer:	MURAOKA Taro <koron@tka.att.ne.jp>
" Author:	Yasuhiro Matsumoto <mattn_jp@hotmail.com>
" Last Change:	28-Oct-2010.

if !exists('g:excitetranslate_options')
  let g:excitetranslate_options = 'register,buffer'
endif

let s:excite_web = 'http://www.excite.co.jp/world/english/'

function! s:CheckEorJ(word)
  let all = strlen(a:word)
  let eng = strlen(substitute(a:word, '[^\t -~]', '', 'g'))
  return eng * 2 < all ? 'JAEN' : 'ENJA'
endfunction

function! ExciteTranslate(word, ...)
  let mode = a:0 >= 2 ? a:2 : s:CheckEorJ(a:word)
  let @a= mode
  " Makeup query data chunk
  let chunk = 'before=' . AL_urlencode(a:word) . '&'
  let chunk = chunk . 'wb_lp=' . mode
  let resfile = tempname()
  let tmpfile = tempname()
  exec 'redir! > ' . tmpfile 
  silent echo chunk
  redir END
  " Do query with curl.
  call AL_echo('Translating...', 'WarningMsg')
  let ret = system('curl -d @' . AL_quote(tmpfile) . ' -o ' . AL_quote(resfile) . ' ' . s:excite_web)
  redraw!
  " Format result string.
  call AL_execute('1split ' . resfile)
  silent! %v/^<textarea /d _
  silent! %v/name="after"/d _
  silent! %s/<[^>]*>//g
  let line = getline(1)
  silent bw!
  " Remove temporary files
  call delete(resfile)
  call delete(tmpfile)
  " Return the result
  return AL_decode_entityreference(line)
endfunction

function! ExciteTranslateRange() range
  " Concatenate input string.
  let curline = a:firstline
  let strline = ''
  while curline <= a:lastline
    let tmpline = AL_chompex(getline(curline))
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
  if AL_hasflag(g:excitetranslate_options, 'buffer')
    " Open or go result buffer.
    let bufname = '==Translate== Exicte'
    let winnr = bufwinnr(bufname)
    if winnr < 1
      call AL_execute('below new '.escape(bufname, ' ')) 
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
  if AL_hasflag(g:excitetranslate_options, 'register')
    let @" = jstr
  endif
endfunction

command! -nargs=0 -range ExciteTranslate <line1>,<line2>call ExciteTranslateRange()

