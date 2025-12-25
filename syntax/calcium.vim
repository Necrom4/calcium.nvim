if exists("b:current_syntax")
  finish
endif

" Integers and floats
syntax match calciumNumber /\v<\d+(\.\d+)?>/
highlight default link calciumNumber Number

" Variables
syntax match calciumVariable /\v<[a-zA-Z_]\w*>/
if hlexists('@variable.member')
  highlight default link calciumVariable @variable.member
else
  highlight default link calciumVariable DiagnosticHint
endif

" Result
syntax region calciumResult
      \ start=/\v[^=~><][=]\s*\zs[a-zA-Z0-9]/
      \ end=/$/
      \ contains=calciumResultNumber,calciumResultBoolean
      \ keepend

syntax match calciumResultNumber /\v\d+(\.\d+)?>/ contained
highlight default link calciumResultNumber Special

syntax match calciumResultBoolean /\v<(true|false)>/ contained
highlight default link calciumResultBoolean Special

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
