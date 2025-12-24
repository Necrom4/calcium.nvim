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

" Brackets
syntax match calciumBracket /[()\[\]{}]/
if hlexists('@punctuation.bracket')
  highlight default link calciumBracket @punctuation.bracket
else
  highlight default link calciumBracket Delimiter
endif

" Function call region: name(...)
syntax region calciumFunctionCall
  \ start=/\v<[a-zA-Z_]\w*\(/
  \ end=/)/
  \ contains=calciumFunctionName,calciumFuncParen,calciumNumber
  \ keepend

" Function name
syntax match calciumFunctionName /\v<[a-zA-Z_]\w*/ contained
highlight default link calciumFunctionName Function


let b:current_syntax = "calcium"
