#!/usr/bin/env lua
-- ltm_welc -- a tiny console greeting.

-- Program vars
local logo = [[

█    ▀█▀ █▄ ▄█     █    ▀█▀ █▀▀▀ ▀█▀
█     █  █ █ █ ▀▀▀ █     █  ▀▀▀█  █
▀▀▀▀  ▀  ▀   ▀     ▀▀▀▀ ▀▀▀ ▀▀▀▀  ▀
───────────────────────────────────
]]

local columns = 3

-- Welcome page
local python_program = {
    "dvi",
    "dins",
    "gh",
    "snk",
    "tls",
    "vfx",
    "imgsh",
    "calc",
    "vol",
    "cld",
    "keyfix",
    "qrc",
    "notelp", 
}

local lua_program = {
    "ltm_welc",
    "notelp",
}

local function print_programs(code_array) 
    print("───────────────────────────────────")
    for i, name in ipairs(code_array) do
        io.write(" " .. name)

        if i == #code_array then
            io.write(".\n")
        elseif i % columns == 0 then
            io.write(",\n")
        else
            io.write(",")
        end
    end
end

local function show_welcome_page()
    print("A collection of useful CLI utilities\nfor everyday tasks.")

    print("\n\27[96m Python programs\27[0m")
    print_programs(python_program)

    print("\n\27[96m Lua programs\27[0m")
    print_programs(lua_program)

    print("")
end

-- Help page
local python_program_desc = {
    "dvi - download video and images",
    "dins - find file in directory",
    "gh - open GitHub in browser",
    "snk - snake game",
    "tls - translator",
    "vfx - visual effects in terminal",
    "imgsh - image processing",
    "calc - terminal calculator",
    "vol - terminal audio player",
    "cld - clear screenshots and downloads",
    "keyfix - Fix text typed in the wrong keyboard layout",
    "qrc - QR code generator",
}

local lua_program_desc = {
    "ltm_welc - welcome",
    "notelp - notes",
}

local function print_help(code_array)
    print("───────────────────────────────────")
    for i, name in ipairs(code_array) do
        io.write(" " .. name)

        if i == #code_array then
            io.write(".\n")
        else
            io.write(",\n")
        end
    end
end

local function show_help_page()
    print("Ltm_list documentation.")
    
    print("\n\27[96m Python programs :\27[0m")
    print_help(python_program_desc)

    print("\n\27[96m Lua programs :\27[0m")
    print_help(lua_program_desc)
end

-- Main
local function main()
    print(logo)
    if arg[1] == "-h" then
        show_help_page()
    else
        show_welcome_page()
    end
end


-- start
main()