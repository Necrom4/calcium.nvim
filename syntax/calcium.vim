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

" Function call region: name(...)
syntax region calciumFunctionCall
  \ start=/\v<[a-zA-Z_]\w*\(/
  \ end=/)/
  \ contains=calciumFunctionName,calciumFuncParen,calciumNumber
  \ keepend

" Function name
syntax match calciumFunctionName /\v<[a-zA-Z_]\w*/ contained
highlight default link calciumFunctionName Function

" Function parentheses
syntax match calciumFuncParen /[()]/ contained
highlight default link calciumFuncParen Delimiter

let b:current_syntax = "calcium"
