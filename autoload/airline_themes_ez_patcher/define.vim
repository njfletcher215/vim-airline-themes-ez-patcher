" expand the definition of the item at the given path in the given palette recursively
" raises an error if there are too many redirects, or if the path and/or palette are malformed
" a:path is a list where the first entry is the palette containing the entry you wish to define,
" and the remaining entries are the path to the entry you wish to define
" ex. foo = {bar: {baz: {qux: 'spam'}}} -> path = [foo, 'bar', 'baz', 'qux']
" a:palette is the palette where you wish to define the entry -- it will typically match a:path[0]
function! airline_themes_ez_patcher#define#define(path, palette, num_redirects) abort
    let l:defined = []

    if a:num_redirects > g:airline_themes_ez_patcher#max_redirects
        throw 'Too many redirects when resolving palette references! If you legitimately need more than ' . g:airline_themes_ez_patcher#max_redirects . ' redirects, please increase the value of g:airline_themes_ez_patcher#max_redirects'
    endif

    " verify the path is valid
    if len(a:path) <= 1
        throw "Can't expand reference. Path too short! Check the structure of your palette\npath: " . string(a:path)
    elseif len(a:path) > 5
        throw "Can't expand reference. Path too long! Check the structure of your palette\npath: " . string(a:path)
    endif

    " initialize parent and last key (aka the key we are actually defining)
    let l:last_key = a:path[-1]
    let l:parent = a:path[0]
    for l:key in a:path[1:-2]
        if !has_key(l:parent, l:key)
            throw "Can't expand reference. Invalid path! Check the structure of your palette\npath: " . string(a:path)
        endif
        let l:parent = l:parent[l:key]
    endfor

    " if the last key doesn't exist
    if !has_key(l:parent, l:last_key)
        " if this is a modified section and there is a corresponding non-modified section, set to reference the non-modified section
        " (only applicable to full paths)
        if len(a:path) >= 5 && stridx(a:path[3], '_') >= 0  " the only multi-word sections are modified sections
            let a:path[0][a:path[1]][a:path[2]][a:path[3]] = substitute(a:path[0][a:path[1]][a:path[2]][a:path[3]], '_.*$', '', '')
        " else if there is a base section, set to reference the base scopy the values from the non-modified sectionection
        elseif has_key(a:path[0], 'base')
            let a:path[0][a:path[1]][a:path[2]][a:path[3]] = 'base'
        " else set to reference 'default'
        else
            let a:path[0][a:path[1]][a:path[2]][a:path[3]] = 'default'
        endif
    endif

    " if the last key is explicitly using the 'default' keyword, set the value to the default
    if l:last_key == 'default'
        let l:default = g:airline_themes_ez_patcher#default_palette['default']
        for l:key in a:path[2:]
            if !has_key(l:default, l:key)
                throw "Can't get default value. Invalid path! Check the structure of the default palette, g:airline_themes_ez_patcher#default_palette"
            endif
            let l:default = l:default[l:key]
        endfor
        let l:parent[l:last_key] = l:default
    endif

    " if the last key is an actual color value, just return
    if (l:last_key == 'hexcode' && type(l:parent[l:last_key]) == v:t_string && l:parent[l:last_key] =~ '^#[0-9a-fA-F]\{6}$') ||
       \ (l:last_key == 'Xterm' && type(l:parent[l:last_key]) == v:t_number && l:parent[l:last_key] >= 0 && l:parent[l:last_key] <= 255)
        return l:defined + [l:last_key]
    endif

    " if the key is a color using the 'auto' keyword, translate it from the other color in the mode
    if (l:last_key == 'hexcode' || l:last_key == 'Xterm') && l:parent[l:last_key] == 'auto'
        let l:other_color = l:last_key == 'hexcode' ? 'Xterm' : 'hexcode'

        " verify the other color is defined
        if !has_key(l:parent, l:other_color)
            throw "Can't automatically parse color. Other color not defined! Check the structure of your palette\nother_color: " . l:other_color
        endif

        " verify the other color is not also set to 'auto'
        if l:parent[l:other_color] == 'auto'
            throw "Can't automatically parse color. Both colors are set to 'auto'! Check the structure of your palette\nother_color: " . l:other_color
        endif

        " if the other color is a reference, define it
        if type(l:parent[l:other_color]) == v:t_string &&  " value is a string
            !(l:other_color == 'hexcode' && l:parent[l:other_color] =~ '^#[0-9a-fA-F]\{6}$')  " but not a hexcode set to a valid hexcode
            let l:ref_path = a:path[0:-1] + [l:other_color]
            call extend(l:defined, airline_themes_ez_patcher#define#define(l:ref_path, a:palette, a:num_calls + 1))
        endif

        " translate the other color and copy it
        let l:parent[l:last_key] = airline_themes_ez_patcher#utils#translate_color(l:parent[l:other_color])

    " if the last key is a reference to another path, define that path and copy the values
    " NOTE: keywords and hexcodes have already been processed, so anything that is still a string is a reference
    elseif type(l:parent[l:last_key]) == v:t_string
        let l:ref_path = split(l:parent[l:last_key], '\.')  " NOTE this path will NOT include your palette, we will prepend it later, after we determine what palette to use
        " if the reference path is longer than the current path, the reference isn't valid
        if len(l:ref_path) > len(a:path) - 1  " -1 because we are not including the palette yet
            throw "Can't expand reference. Reference path too long! Reference path cannot be longer than the path it will be written to\nreference path: " . l:parent[l:last_key] . "\npath: " . string(a:path)
        endif
        " if the reference path is shorter than the path, fill it in with the path
        for l:i in range(len(a:path) - 1)  " again, -1 to account for the palette
            if l:i >= len(l:ref_path)
                call add(l:ref_path, a:path[l:i + 1])
            endif
        endfor

        " copy the reference according to the format of the containing palette
        " if the reference is to another section in the same palette, it is just a simple copy
        if has_key(a:path[0], l:ref_path[0])
            " prepend the palette to the reference path
            let l:ref_path = [a:path[0]] + l:ref_path
            " define the reference if it hasn't been defined yet
            call extend(l:defined, airline_themes_ez_patcher#define#define(l:ref_path, a:palette, a:num_redirects + 1))
            let l:ref_value = g:airline_themes_ez_patcher#palette
            for l:key in l:ref_path
                let l:ref_value = l:ref_value[l:key]  " don't need the guard because we know the path is valid
            endfor
            let l:parent[l:last_key] = l:ref_value

        " if the reference is to airline's palette, its a different format
        " since we may have to do a deep copy, we will use a recursive function
        elseif has_key(a:palette['normal'], l:ref_path[0])
            " prepend the palette to the reference path
            let l:ref_path = [a:palette] + l:ref_path
            call airline_themes_ez_patcher#copy#from_airline(l:ref_path, a:path)

        " if the section name isn't in either path, the reference is obviously invalid
        else
            throw "Can't expand reference. Section does not exist! Check the structure of your palette\nreference path: " . l:parent[l:last_key] . "\npath: " . string(a:path)
        endif

    " if the last key is an object, define each of its children
    elseif type(l:parent[l:last_key]) == v:t_dict
        let l:keys_remaining = copy(airline_themes_ez_patcher#utils#get_complete_keyset(a:path))
        while len(l:keys_remaining) > 0
            let l:processed = airline_themes_ez_patcher#define#define(a:path + [l:keys_remaining[0]], a:palette, a:num_redirects + 1)
            for l:key in l:processed
                let l:index = index(l:keys_remaining, l:key)
                if l:index != -1
                    call remove(l:keys_remaining, l:index)
                endif
            endfor
        endwhile

    " if its not a color actual value, color keyword, reference, or object, then it is invalid data
    else
        throw "Can't expand reference. Invalid data! Check the structure of your palette\nvalue: " . l:parent[l:last_key]
    endif

    return l:defined + [l:last_key]
endfunction


