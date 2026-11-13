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
}

-- Main
local function main()
    -- Print Logo
    print([[

█    ▀█▀ █▄ ▄█     █    ▀█▀ █▀▀▀ ▀█▀
█     █  █ █ █ ▀▀▀ █     █  ▀▀▀█  █
▀▀▀▀  ▀  ▀   ▀     ▀▀▀▀ ▀▀▀ ▀▀▀▀  ▀
    ]])

    print(" A collection of useful CLI utilities for everyday tasks.")

    print("Programs:")

    for i, name in ipairs(python_program) do
        print(" " .. name)
    end

    for i, name in ipairs(lua_program) do
        print(" " .. name)
    end
    
end


-- start
main()