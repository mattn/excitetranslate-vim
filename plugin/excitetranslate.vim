" vim:set ts=8 sts=2 sw=2 tw=0:
"
" excitetranslate.vim - Translate between English and Japanese using Excite
"
" Maintainer:	MURAOKA Taro <koron@tka.att.ne.jp>
" Author:	Yasuhiro Matsumoto <mattn_jp@hotmail.com>
" Last Change:	29-Oct-2010.

if !exists('g:excitetranslate_options')
  let g:excitetranslate_options = ["register","buffer"]
endif

let s:endpoint = 'http://www.excite.co.jp/world/english/'

function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! s:CheckEorJ(word)
  let all = strlen(a:word)
  let eng = strlen(substitute(a:word, '[^\t -~]', '', 'g'))
  return eng * 2 < all ? 'JAEN' : 'ENJA'
endfunction

function! ExciteTranslate(word, ...)
  let mode = a:0 >= 2 ? a:2 : s:CheckEorJ(a:word)
  let @a= mode
  let res = http#post(s:endpoint, {"before": a:word, "wb_lp": mode})
  let text = iconv(res.content, "utf-8", &encoding)
  let mx = '^.*<textarea name="after" id="after">'
  let text = substitute(matchstr(text, mx), mx, '', '')
  let mx = '</textarea>.*$'
  let text = substitute(matchstr(text, mx), mx, '', '')
  let text = substitute(text, '&gt;', '>', 'g')
  let text = substitute(text, '&lt;', '<', 'g')
  let text = substitute(text, '&quot;', '"', 'g')
  let text = substitute(text, '&apos;', "'", 'g')
  let text = substitute(text, '&nbsp;', ' ', 'g')
  let text = substitute(text, '&yen;', '\&#65509;', 'g')
  let text = substitute(text, '&#\(\d\+\);', '\=s:nr2enc_char(submatch(1))', 'g')
  let text = substitute(text, '&amp;', '\&', 'g')
  return text
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
    let bufname = '==Translate== Excite'
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
