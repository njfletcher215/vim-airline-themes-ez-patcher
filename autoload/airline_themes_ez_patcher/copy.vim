" copy the entry in the airline palette to the g:airline_themes_ez_patch#palette recursively
" NOTE the first element of from_path should be the palette
function! airline_themes_ez_patcher#copy#from_airline(from_path, to_path)
    " verify paths are the same length
    if len(a:from_path) != len(a:to_path)
        throw "Can't copy color from airline palette. Paths are not the same length! Check the structure of your palette\nfrom_path: " . string(a:from_path) . "\nto_path: " . string(a:to_path)
    endif

    " verify paths are a valid length
    if len(a:from_path) > 5
        throw "Can't copy color from airline palette. Paths too long! Check the structure of your palette\nfrom_path: " . string(a:from_path) . "\nto_path: " . string(a:to_path)
    endif
    if len(a:from_path) == 0
        throw "Can't copy color from airline palette. No paths given!"
    endif

    " if the last key is not already in the palette, define it with a default value
    let l:last_key = a:to_path[-1]
    let l:parent = a:to_path[0]
    for l:key in a:to_path[1:-2]
        if !has_key(l:parent, l:key)
            throw "Can't copy color from airline palette. Invalid path! Check the structure of your palette\nfrom_path: " . string(a:from_path) . "\nto_path: " . string(a:to_path)
        endif
        let l:parent = l:parent[l:key]
    endfor
    let l:parent[l:last_key] = {}  " colors will be overwritten with a string or number value, everything else can keep the empty dictionary

    " if the last key is a color, copy it from the airline palette
    if len(a:from_path) == 5
        " if the mode is 'base', or the mode is not defined for this section (or at all), use the 'normal' mode (I believe this mirrors airline behavior)
        if a:from_path[3] == 'base' || !has_key(a:from_path[0], a:from_path[3]) || !has_key(a:from_path[0][a:from_path[3]], a:from_path[1])
            let a:from_path[3] = 'normal'
        endif

        " airline groups color definitions differently:
        " instead of section -> ground -> mode -> color -> value,
        " they have mode -> section -> [hexcode foreground value, hexcode background value, Xterm foreground value, Xterm background value]
        let l:index = airline_themes_ez_patcher#utils#get_airline_index(a:from_path)
        let l:value = a:from_path[0][a:from_path[3]][a:from_path[1]][l:index]
        let a:to_path[0][a:to_path[1]][a:to_path[2]][a:to_path[3]][a:to_path[4]] = a:to_path[4] == 'Xterm' ? str2nr(l:value) : l:value

    " if the last key is not a color, call this function recursively on all of its children
    else
        let l:complete_keyset = airline_themes_ez_patcher#utils#get_complete_keyset(a:to_path)
        for l:key in l:complete_keyset
            call airline_themes_ez_patcher#copy#from_airline(copy(a:from_path) + [l:key], copy(a:to_path) + [l:key])
        endfor
    endif
endfunction



" copy the given path to the airline palette
function! airline_themes_ez_patcher#copy#to_airline(from_path, to_path)
    " ignore any 'base' entries
    if len(a:from_path) >= 4 && a:from_path[3] == 'base'
        return
    endif

    " verify paths are the same length
    if len(a:from_path) != len(a:to_path)
        throw "Can't copy color to airline palette. Paths are not the same length! Check the structure of your palette\nfrom_path: " . string(a:from_path) . "\nto_path: " . string(a:to_path)
    endif

    " verify paths are a valid length
    if len(a:from_path) > 5
        throw "Can't copy color to airline palette. Paths too long! Check the structure of your palette\nfrom_path: " . string(a:from_path) . "\nto_path: " . string(a:to_path)
    endif
    if len(a:from_path) == 0
        throw "Can't copy color to airline palette. No paths given!"
    endif

    " if the last key is a color, copy it to the airline palette
    if len(a:from_path) == 5
        " airline groups color definitions differently:
        " instead of section -> ground -> mode -> color -> value,
        " they have mode -> section -> [hexcode foreground value, hexcode background value, Xterm foreground value, Xterm background value]

        " create the mode object if it does not already exist
        if !has_key(a:to_path[0], a:to_path[3])
            let a:to_path[0][a:to_path[3]] = {}
        endif
        " create the section array if it does not already exist
        if !has_key(a:to_path[0][a:to_path[3]], a:to_path[1])
            let a:to_path[0][a:to_path[3]][a:to_path[1]] = repeat([''], 4)
        endif

        let l:index = airline_themes_ez_patcher#utils#get_airline_index(a:from_path)
        let a:to_path[0][a:to_path[3]][a:to_path[1]][l:index] = a:from_path[0][a:from_path[1]][a:from_path[2]][a:from_path[3]][a:from_path[4]]
    " if the last key is not a color, call this function recursively on all of its children
    else
        let l:last_value = a:from_path[0]
        for l:key in a:from_path[1:]
            let l:last_value = l:last_value[l:key]
        endfor
        for l:key in keys(l:last_value)
            call airline_themes_ez_patcher#copy#to_airline(copy(a:from_path) + [l:key], copy(a:to_path) + [l:key])
        endfor
    endif
endfunction

