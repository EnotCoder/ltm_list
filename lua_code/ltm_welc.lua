#!/usr/bin/env lua
-- ltm_welc -- a tiny console greeting.

-- Programs
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
}

local lua_program = {
    "ltm_welc",
    "notelp",
}

local logo = [[

█    ▀█▀ █▄ ▄█     █    ▀█▀ █▀▀▀ ▀█▀
█     █  █ █ █ ▀▀▀ █     █  ▀▀▀█  █
▀▀▀▀  ▀  ▀   ▀     ▀▀▀▀ ▀▀▀ ▀▀▀▀  ▀
───────────────────────────────────
]]

local columns = 3
local indent_size = 2

local function print_programs(columns, code_array) 
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

-- Main
local function main()
    print(logo)
    print("A collection of useful CLI utilities\nfor everyday tasks.")

    print("\n\27[96m Python programs\27[0m")
    print_programs(columns, python_program)

    print("\n\27[96m Lua programs\27[0m")
    print_programs(columns, lua_program)

    print("")
    
end


-- start
main()