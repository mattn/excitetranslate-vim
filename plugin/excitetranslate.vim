" vim:set ts=8 sts=2 sw=2 tw=0:
"
" excitetranslate.vim - Translate between English and Japanese using Excite
"
" Maintainer:	MURAOKA Taro <koron@tka.att.ne.jp>
" Author:	Yasuhiro Matsumoto <mattn_jp@hotmail.com>
" Last Change:	03-Apr-2012.

if !exists('g:excitetranslate_options')
  let g:excitetranslate_options = ["register","buffer"]
endif

let s:endpoint = 'https://www.excite.co.jp/world/english_japanese/'

command! -nargs=0 -range ExciteTranslate <line1>,<line2>call excitetranslate#range()

nnoremap <plug>(excitetranslate) :<C-u>call excitetranslate#replace('n')<cr>
xnoremap <plug>(excitetranslate) :<C-u>call excitetranslate#replace('v')<cr>
if !hasmapto('<plug>(excitetranslate)')
  nmap ,E <plug>(excitetranslate)
  xmap ,E <plug>(excitetranslate)
endif
