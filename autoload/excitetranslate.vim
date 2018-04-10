let s:endpoint = 'https://www.excite.co.jp/world/english_japanese/'

function! s:CheckEorJ(word)
  let all = strlen(a:word)
  let eng = strlen(substitute(a:word, '[^\t -~]', '', 'g'))
  return eng * 2 < all ? 'JAEN' : 'ENJA'
endfunction

function! excitetranslate#translate(word, ...)
  let mode = a:0 >= 2 ? a:2 : s:CheckEorJ(a:word)
  let @a= mode
  let res = webapi#http#post(s:endpoint, {"before": a:word, "wb_lp": mode})
  let dom = webapi#html#parse(iconv(res.content, "utf-8", &encoding))
  let after = dom.find('textarea', {"id": "after"})
  return substitute(after.value(), "\x08", "\n", 'g')
endfunction

function! excitetranslate#range() range
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
  let jstr = excitetranslate#translate(strline)
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
      call setline(1, split(jstr, "\n"))
    else
      call append(line('$'), '--------')
      call append(line('$'), split(jstr, "\n"))
    endif
    normal! Gzt
  endif
  " Put to unnamed register.
  if index(g:excitetranslate_options, 'register') != -1
    let @" = jstr
  endif
endfunction
