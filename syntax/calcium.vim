if exists("b:current_syntax")
  finish
endif

" Integers and floats
syntax match calciumNumber /\v<\d+(\.\d+)?>/
highlight default link calciumNumber Number

" Result
syntax region calciumResult
  \ start=/=/
  \ end=/$/
  \ contains=calciumResultNumber
  \ keepend

syntax match calciumResultNumber /\v\d+(\.\d+)?>/ contained
highlight default link calciumResultNumber Special

" Functions
syntax match calciumFunctionCall /\v<[a-zA-Z_]\w*\(/ contains=calciumFunctionName
" Highlight only the name part
syntax match calciumFunctionName /\v<[a-zA-Z_]\w*/ contained
highlight default link calciumFunctionName Function

let b:current_syntax = "calcium"
