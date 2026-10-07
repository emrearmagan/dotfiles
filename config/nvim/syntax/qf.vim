if exists('b:current_syntax')
    finish
endif

syn match qfFileName /^[^│]*/ nextgroup=qfSeparatorLeft
syn match qfSeparatorLeft /│/ contained nextgroup=qfLineNr
syn match qfLineNr /[^│]*/ contained nextgroup=qfSeparatorRight
syn match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote,qfText
syn match qfError / E .*$/ contained
syn match qfWarning / W .*$/ contained
syn match qfInfo / I .*$/ contained
syn match qfNote / [NH] .*$/ contained
syn match qfText / .*$/ contained contains=qfString,qfNumber,qfKeyword,qfFunction

syn region qfString start=+"+ skip=+\\"+ end=+"+ contained
syn region qfString start=+'+ skip=+\\'+ end=+'+ contained
syn match qfNumber /\<\d\+\>/ contained
syn keyword qfKeyword function def class return if else elseif elif for while end local const let var import from export contained
syn match qfFunction /\<\h\w*\(\.\w\+\|:\w\+\)*\ze(/ contained

hi def link qfFileName Directory
hi def link qfSeparatorLeft Delimiter
hi def link qfSeparatorRight Delimiter
hi def link qfLineNr LineNr
hi def link qfError DiagnosticError
hi def link qfWarning DiagnosticWarn
hi def link qfInfo DiagnosticInfo
hi def link qfNote DiagnosticHint
hi def link qfString String
hi def link qfNumber Number
hi def link qfKeyword Keyword
hi def link qfFunction Function

let b:current_syntax = 'qf'
