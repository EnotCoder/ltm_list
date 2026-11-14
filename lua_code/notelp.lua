#!/usr/bin/env lua
-- notelp — a tiny CLI notebook.

-- Notes live in a stable per-user location instead of the current directory,
-- so the same notebook is used no matter where the command is started.
local function resolve_notes_path()
    local override = os.getenv("NOTELP_FILE")

    if override and override ~= "" then
        return override
    end

    local base = os.getenv("XDG_DATA_HOME")

    if not base or base == "" then
        local home = os.getenv("HOME")

        if not home or home == "" then
            return nil, "neither NOTELP_FILE, XDG_DATA_HOME nor HOME is set"
        end

        base = home .. "/.local/share"
    end

    return base .. "/notelp/notelp.txt"
end

local notes_file, notes_path_error = resolve_notes_path()

-- Quote a value for a POSIX shell command line.
local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function ensure_parent_directory(path)
    local directory = path:match("^(.*)/[^/]+$")

    if not directory or directory == "" then
        return true
    end

    local result = os.execute("mkdir -p " .. shell_quote(directory))

    -- Lua 5.1 returns a status code, Lua 5.2+ returns true on success.
    if result == true or result == 0 then
        return true
    end

    return nil, "could not create directory: " .. directory
end

local function load_notes()
    if not notes_file then
        return nil, notes_path_error
    end

    local notes = {}
    local file, err, code = io.open(notes_file, "r")

    if not file then
        -- Файла ещё нет — начинаем с пустого списка.
        if code == 2 or (err and err:lower():match("no such file")) then
            return notes
        end

        return nil, err
    end

    for line in file:lines() do
        notes[#notes + 1] = line:gsub("\r$", "")
    end

    file:close()
    return notes
end

local function save_notes(notes)
    if not notes_file then
        return nil, notes_path_error
    end

    local ok, dir_err = ensure_parent_directory(notes_file)

    if not ok then
        return nil, dir_err
    end

    -- Write to a temporary file first so an interrupted save cannot corrupt
    -- the existing notebook.
    local tmp_file = notes_file .. ".tmp"
    local file, err = io.open(tmp_file, "w")

    if not file then
        return nil, err
    end

    for _, note in ipairs(notes) do
        local written, write_err = file:write(note, "\n")

        if not written then
            file:close()
            os.remove(tmp_file)
            return nil, write_err
        end
    end

    local closed, close_err = file:close()

    if not closed then
        os.remove(tmp_file)
        return nil, close_err
    end

    local renamed, rename_err = os.rename(tmp_file, notes_file)

    if not renamed then
        os.remove(tmp_file)
        return nil, rename_err
    end

    return true
end

local function print_help()
    print("Usage:")
    print('  notelp add "Note text"')
    print("  notelp list")
    print("  notelp show 1")
    print("  notelp delete 1")
    print("  notelp help")
    print("")
end

local function valid_index(value, notes)
    local index = tonumber(value)

    if not index
        or index % 1 ~= 0
        or index < 1
        or index > #notes
    then
        return nil
    end

    return index
end

local function main()
    local command = arg[1] or "help"

    if command == "help" then
        print("\27[96mNotelp\27[0m — a tiny CLI notebook\n")
        print_help()
        return
    end

    if command ~= "add"
        and command ~= "list"
        and command ~= "show"
        and command ~= "delete"
    then
        print("\27[31mUnknown command:\27[0m " .. command .. "\n")
        print_help()
        return
    end

    local notes, err = load_notes()

    if not notes then
        io.stderr:write("Could not load notes: ", tostring(err), "\n")
        os.exit(1)
    end

    if command == "add" then
        -- Собираем все аргументы после add в одну строку.
        local text = table.concat(arg, " ", 2)

        if not text:match("%S") then
            print('Usage: notelp add "Note text"')
            return
        end

        if text:find("[\r\n]") then
            print("Only single-line notes are supported.")
            return
        end

        notes[#notes + 1] = text

        local ok, save_err = save_notes(notes)

        if not ok then
            io.stderr:write(
                "Could not save notes: ",
                tostring(save_err),
                "\n"
            )
            os.exit(1)
        end

        print("  + Note #" .. #notes .. " saved.")

    elseif command == "list" then
        print("\n  notelp / notes")
        print("  " .. string.rep("-", 38))

        if #notes == 0 then
            print("  No notes yet.")
        else
            for i, note in ipairs(notes) do
                print(string.format("  %d  %s", i, note))
            end
        end

        print("\n  " .. #notes .. " notes\n")

    elseif command == "show" then
        local index = valid_index(arg[2], notes)

        if not index then
            print("Invalid note number.")
            return
        end

        print("\n  Note #" .. index)
        print("  " .. notes[index] .. "\n")

    elseif command == "delete" then
        local index = valid_index(arg[2], notes)

        if not index then
            print("Invalid note number.")
            return
        end

        print("  " .. notes[index])
        io.write("  Delete note #" .. index .. "? [y/N]: ")
        io.flush()

        local answer = io.read()
        answer = answer and answer:lower() or ""

        if answer ~= "y" and answer ~= "yes" then
            print("  Cancelled.")
            return
        end

        table.remove(notes, index)

        local ok, save_err = save_notes(notes)

        if not ok then
            io.stderr:write(
                "Could not save notes: ",
                tostring(save_err),
                "\n"
            )
            os.exit(1)
        end

        print("  - Note deleted.")
    end
end

main()
