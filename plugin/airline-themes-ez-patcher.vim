" init
if exists('g:airline_themes_ez_patcher#loaded')
    finish
endif
let g:airline_themes_ez_patcher#loaded = 1

call airline_themes_ez_patcher#globals#init()



" the patch function that must be passed to airline
function! AirlineThemePatch(palette)
    if !exists('g:airline_themes_ez_patcher#palette')
        return
    endif

    " define the default palette
    call airline_themes_ez_patcher#define#define([g:airline_themes_ez_patcher#default_palette, 'default'], a:palette, 0)

    let l:sections = keys(g:airline_themes_ez_patcher#palette)

    " verify all sections begin with 'airline_', since airline will prepend it when adding the sections to the layout
    for l:section in l:sections
        if l:section !~# 'airline_'
            throw "Invalid section name! All sections must begin with 'airline_'. Check the structure of your palette\nsection: " . l:section
        endif
    endfor

    let l:sections_left = keys(g:airline_themes_ez_patcher#palette)

    " iterate through each section and define it
    while len(l:sections_left) > 0
        let l:processed = airline_themes_ez_patcher#define#define([g:airline_themes_ez_patcher#palette, l:sections_left[0]], a:palette, 0)
        for l:section in l:processed
            let l:index = index(l:sections_left, l:section)
            if l:index != -1
                call remove(l:sections_left, l:index)
            endif
        endfor
    endwhile

    " copy the values from g:airline_themes_ez_patcher#palette to the airline palette
    call airline_themes_ez_patcher#copy#to_airline([g:airline_themes_ez_patcher#palette], [a:palette])


    " append each section that isn't already laid out
    for l:section in g:airline_themes_ez_patcher#layout
        if index(g:airline#extensions#default#layout[0], l:section) < 0 && index(g:airline#extensions#default#layout[1], l:section) < 0
            call add(g:airline#extensions#default#layout[1], l:section)
        endif
    endfor
    for l:section in keys(g:airline_themes_ez_patcher#palette)
        if index(g:airline#extensions#default#layout[0], l:section) < 0 && index(g:airline#extensions#default#layout[1], l:section) < 0
            call add(g:airline#extensions#default#layout[1], l:section)
        endif
    endfor
endfunction

" the name of the above patch func
" DO NOT CHANGE unless you have written your own patch func
" if you do wish to extend this patch func with your own (not advised),
" remember to call AirlineThemePatch somewhere in your function
let g:airline_theme_patch_func = 'AirlineThemePatch'

