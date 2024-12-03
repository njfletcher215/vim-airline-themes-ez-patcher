" default values for each global variable
let s:defaults = {
    \ 'airline_themes_ez_patcher#default_palette': {
        \ 'default': 'airline_a'
    \ },
    \ 'airline_themes_ez_patcher#layout': [],
    \ 'airline_themes_ez_patcher#max_redirects': 5,
    \ 'airline_themes_ez_patcher#palette': {},
    \ 'airline#extensions#default#layout': [
        \ [ 'a', 'b', 'c' ],
        \ [ 'x', 'y', 'z', 'error', 'warning' ]
    \ ],
\ }



" initialize global variables, if they do not already exist
function! airline_themes_ez_patcher#globals#init()
    " default values for sections undefined in the palette
    " default behavior is to copy airline section a
    let g:airline_themes_ez_patcher#default_palette = get(g:, 'airline_themes_ez_patcher#default_palette', s:defaults['airline_themes_ez_patcher#default_palette'])

    " the order in which to append sections to the airline bar
    " appends the sections to the very end of the airline bar,
    " sections can also be added to g:airline#extensions#default#layout seperately
    " (NOTE: g:airline#extensions#default#layout takes precedence)
    " sections that are defined in neither layout
    " will be appended in an indeterminite order
    let g:airline_themes_ez_patcher#layout = get(g:, 'airline_themes_ez_patcher#layout', s:defaults['airline_themes_ez_patcher#layout'])

    " number of layers of reference allowed in the palette
    " most users will not need more than 1 or 2,
    " but it can be increased if needed
    let g:airline_themes_ez_patcher#max_redirects = get(g:, 'airline_themes_ez_patcher#max_redirects', s:defaults['airline_themes_ez_patcher#max_redirects'])

    " the dictionary defining every section you wish to add to the airline palette
    let g:airline_themes_ez_patcher#palette = get(g:, 'airline_themes_ez_patcher#palette', s:defaults['airline_themes_ez_patcher#palette'])

    " the layout of the airline bar
    let g:airline#extensions#default#layout = get(g:, 'airline#extensions#default#layout', s:defaults['airline#extensions#default#layout'])

    let g:test = 1
endfunction

