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
syntax match calciumResult /\v[^=~<>][=]\s*\zs[a-zA-Z0-9\.]*/
highlight default link calciumResult Special

" Brackets
syntax match calciumBracket /[()\[\]{}]/
if hlexists('@punctuation.bracket')
  highlight default link calciumBracket @punctuation.bracket
else
  highlight default link calciumBracket Delimiter
endif

" Re-use answer
syntax match calciumAnswer /\v<(ans|_)>/
highlight default link calciumAnswer Special

" Function name
syntax match calciumFunctionName /\v<[A-Za-z_][A-Za-z0-9_]*\ze\(/
if hlexists('@keyword.function')
  highlight default link calciumFunctionName @keyword.function
else
  highlight default link calciumFunctionName Function
endif

let b:current_syntax = "calcium"
