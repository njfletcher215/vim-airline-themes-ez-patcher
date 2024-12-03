" all valid grounds, modes, and color types
let s:COMPLETE_KEYSETS = [
    \ ['foreground', 'background'],
    \ ['base',
    \  'normal', 'insert', 'replace', 'visual', 'inactive', 'terminal',
    \  'normal_modified', 'insert_modified', 'replace_modified', 'visual_modified', 'inactive_modified', 'terminal_modified',
    \  'normal_paste', 'insert_paste', 'replace_paste', 'visual_paste', 'inactive_paste', 'terminal_paste'],
    \ ['hexcode', 'Xterm']
\ ]
lockvar s:COMPLETE_KEYSETS



" gets all valid keys for the next level of the given path
" ie. when passed a section, returns all valid grounds;
" when passed a ground, returns all valid modes;
" when passed a mode, returns all valid color types
" raises an error when passing a path ending in a palette or a color type
" since palette subkeys (sections) are arbitrary, and color types dont have subkeys
function! airline_themes_ez_patcher#utils#get_complete_keyset(path)
    " validate the path ends in a section, ground, or mode
    " (ie. is length 2-4)
    if len(a:path) == 0
        throw "Can't get complete keyset. No path given!"
    endif
    if len(a:path) == 1
        throw "Can't get complete keyset. Path too short! Palettes don't have complete keysets!\npath: " . string(a:path)
    endif
    if len(a:path) > 4
        throw "Can't get complete keyset. Path too long! Check the structure of your palette.\npath: " . string(a:path)
    endif

    return copy(s:COMPLETE_KEYSETS[len(a:path) - 2])
endfunction



" translates a color from hexcode representation to Xterm representation, and vice-versa
" hexcodes should be passed (and will be returned) as strings beginning with '#'
" Xterm colors should be passed (and will be returned) as numbers
" raises an error if the passed color is not a properly formatted hexcode or valid Xterm color
" hexcodes are not case sensitive. Xterm colors are integers 0-255
function! airline_themes_ez_patcher#utils#translate_color(color)
    " if the color is a hexcode, convert it to Xterm
    if type(a:color) == v:t_string
        " validate hexcode format
        if a:color !=~ '^#[0-9a-fA-F]\{6}$'
            throw "Can't translate color. String is an invalid hexcode! Doesn't match '^#[0-9a-fA-F]\\{6}$'. Check the structure of your palette.\nhexcode: " . a:color
        endif

        " convert the hexcode to RGB
        let l:r = str2nr(strpart(a:color, 1, 2), 16)
        let l:g = str2nr(strpart(a:color, 3, 2), 16)
        let l:b = str2nr(strpart(a:color, 5, 2), 16)

        " calculate the nearest 256-color code
        if l:r == l:g && l:g == l:b  " if the color is greyscale
            if l:r < 8  " if the color is black
                return 16
            elseif l:r > 248  " if the color is white
                return 231
            else  " if the color is grey
                return float2nr(round((l:r - 8) / 10)) + 232
            endif
        else  " if the color is not greyscale, calculate using the color cube
            let l:r = float2nr(round(l:r / 51.0))
            let l:g = float2nr(round(l:g / 51.0))
            let l:b = float2nr(round(l:b / 51.0))
            return l:r * 36 + l:g * 6 + l:b + 16
        endif
    " else if the color is an Xterm, convert it to hexcode
    elseif type(a:color) == v:t_number
        " validate Xterm range
        if a:color < 0 || a:color > 255 || a:color == float2nr(a:color)
            throw "Can't translate color. Number is an invalid Xterm color! Xterm colors are integers 0-255. Check the structure of your palette\nXterm: " . a:color
        endif

        " define color lookup tables
        let l:basic16 = [
        \     '000000', 'CC0000', '00CC00', 'CCCC00', '0000CC', 'CC00CC', '00CCCC', 'E5E5E5',
        \     '7F7F7F', 'FF0000', '00FF00', 'FFFF00', '5C5CFF', 'FF00FF', '00FFFF', 'FFFFFF'
        \ ]
        let l:colorCube = [0x00, 0x5F, 0x87, 0xAF, 0xD7, 0xFF]
        let l:greyRamp = [
        \     0x08, 0x12, 0x1C, 0x26, 0x30, 0x3A, 0x44, 0x4E, 0x58, 0x62, 0x6C, 0x76,
        \     0x80, 0x8A, 0x94, 0x9E, 0xA8, 0xB2, 0xBC, 0xC6, 0xD0, 0xDA, 0xE4, 0xEE
        \ ]

        if a:color < 16  " if color is one of the basic 16
            return "#" . l:basic16[a:color]
        elseif a:color >= 232  " if the color is grey
            let l:grey = l:greyRamp[a:color - 232]
            return printf('#%02X%02X%02X', l:grey, l:grey, l:grey)
        else  " else the color is in the color cube
            let l:color = a:color - 16
            let l:r = l:colorCube[l:color / 36]
            let l:g = l:colorCube[(l:color % 36) / 6]
            let l:b = l:colorCube[l:color % 6]
            return printf('#%02X%02X%02X', l:r, l:g, l:b)
    else
        throw "Can't translate color. Invalid color! Value is neither a string nor a number. Check the structure of your palette\nvalue: " . a:color
endfunction



" parse the index of the color in the airline palette color list from the path
" the airline palette is organized as 
" mode: {
"   section: [hexcode foreground, hexcode background, Xterm foreground, Xterm background]
" }
" whereas g:airline_themes_ez_patcher#palette is organized as
" section: {
"   ground: {
"     mode: {
"       hexcode: <color>,
"       Xterm: <color>
"     }
"   }
" }
" this function simply looks at the ground and color type entries in the path
" and returns the corresponding index in the airline palette color list
" raises an error if the path is not complete or malformed
function! airline_themes_ez_patcher#utils#get_airline_index(path)
    " validate path is complete and not malformed
    if len(a:path) < 5
        throw "Can't get airline index. Not a complete path! Check the structure of your palette\npath: " . string(a:path)
    elseif len(a:path) > 5
        throw "Can't get airline index. Path too long! Check the structure of your palette\npath: " . string(a:path)
    endif

    " the airline palette is organized as 
    " mode: {
    "   section: [hexcode foreground, hexcode background, Xterm foreground, Xterm background]
    " }
    let l:hexcode_foreground_index = 0
    let l:hexcode_background_index = 1
    let l:xterm_foreground_index = 2
    let l:xterm_background_index = 3

    return a:path[4] == 'hexcode' && a:path[2] == 'foreground' ? l:hexcode_foreground_index :
        \ a:path[4] == 'hexcode' ? l:hexcode_background_index :
        \ a:path[2] == 'foreground' ? l:xterm_foreground_index :
        \ l:xterm_background_index
endfunction

