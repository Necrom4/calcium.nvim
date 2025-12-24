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

let b:current_syntax = "calcium"
