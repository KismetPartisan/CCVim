--[[
    CCVIM - A Vim-like text editor for ComputerCraft computers.
    Copyright (C) 2021  Minater247

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local args = {...}

local validArgs = {
    "--version",
    "--term"
}

local unimplementedArgs = {
    "--",
    "-v",
    "-e",
    "-E",
    "-s",
    "-d",
    "-y",
    "-R",
    "-Z",
    "-m",
    "-M",
    "-b",
    "-l",
    "-C",
    "-N",
    "-V",
    "-D",
    "-n",
    "-r",
    "-L",
    "-T",
    "--not-a-term",
    "--ttyfail",
    "-u",
    "--noplugin",
    "-p",
    "-o",
    "-O",
    "+",
    "--cmd",
    "-c",
    "-S",
    "-s",
    "-w",
    "-W",
    "-x",
    "--startuptime",
    "-i",
    "--clean",
    "-h",
    "--help"
}

local version = 0.733
local releasedate = "2022-05-19"

local fileExplorerVer = 0.12

local tab = require("/vim/lib/tab")
local argv = require("/vim/lib/args")
local str = require("/vim/lib/str")
local fil = require("/vim/lib/fil")
local keyseq = require("/vim/lib/keyseq")
local Trie = require("/vim/lib/trie")
local itertools = require("/vim/lib/itertools")
local monitor
local decargs = argv.pull(args, validArgs, unimplementedArgs) --DecodedArguments
local openfiles = {}
local wid, hig = term.getSize()
local running = true
local filelines = {}
local filename = ""
local currCursorX = 1
local currCursorY = 1
local newfile = false
local currFileOffset = 0 --AKA CurrYOffset
local currXOffset = 0
local oldx = nil
local copybuffer = ""
local copytype = nil
local jumpbuffer = {}
local jumpoffset = 0 --offset for t/T jumping before/after a letter
local currfile = 1
local fileContents = {}
local motd = false
local modeMappings = {
    n = Trie.new(),
    i = Trie.new(),
    c = Trie.new(),
}
local mappingCommands = {
    map = {mode = "", remap = true},
    ["map!"] = {mode = "!", remap = true},
    nmap = {mode = "n", remap = true},
    imap = {mode = "i", remap = true},
    cmap = {mode = "c", remap = true},
    noremap = {mode = "", remap = false},
    ["noremap!"] = {mode = "!", remap = false},
    nnoremap = {mode = "n", remap = false},
    inoremap = {mode = "i", remap = false},
    cnoremap = {mode = "c", remap = false},
}
local currentMode = "n"
local noremapFor = 0
local filetypearr = {}
local mobile = false
local linenumbers = false
local lineoffset = 0
local syntaxhighlighting = false
local oldXOffset = 0
local oldFileOffset = 0
local lowspec = false
local autoindent = false
local ignorecase = false
local lastSearchPos
local lastSearchLine
local sessionSearches = {}
local repeatCount0 = 0
local repeatCount1 = 1
local scrollOption = 10
local modeMsg
local typeahead = {}  -- String keys and pseudokeys
local typeaheadUpdates = {}  -- Mouse position updates
local inputProperties = {mouseX = 1, mouseY = 1, pasteData = ""}
local activeModifiers = {}
local prefixedModifiers = {}
local actionsTrie = Trie.new()
local keyNames = {
    [keys.backspace] = "bs",
    [keys.enter] = "cr",
    [keys.tab] = "tab",  -- Consider setting to "esc"?
    [keys.numPadEnter] = "cr",
    [keys.delete] = "del",
    [keys.minus] = "-",
    [keys.equals] = "=",
    [keys.leftBracket] = "[",
    [keys.rightBracket] = "]",
    [keys.semiColon] = ";",
    [keys.apostrophe] = "'",
    [keys.grave] = "`",
    [keys.backslash] = "backslash",
    [keys.comma] = ",",
    [keys.period] = ".",
    [keys.slash] = "/",
    [keys.multiply] = "kmultiply",
    [keys.space] = " ",
    [keys.one] = "1",
    [keys.two] = "2",
    [keys.three] = "3",
    [keys.four] = "4",
    [keys.five] = "5",
    [keys.six] = "6",
    [keys.seven] = "7",
    [keys.eight] = "8",
    [keys.nine] = "9",
    [keys.zero] = "0",
    [keys.numPadAdd] = "kplus",
    [keys.numPadSubtract] = "kminus",
    [keys.numPadDecimal] = "kpoint",
    [keys.numPadEquals] = "kequal",
    [keys.numPadComma] = "kcomma",
    [keys.numPadDivide] = "kdivide",
    [keys.numPad0] = "k0",
    [keys.numPad1] = "k1",
    [keys.numPad2] = "k2",
    [keys.numPad3] = "k3",
    [keys.numPad4] = "k4",
    [keys.numPad5] = "k5",
    [keys.numPad6] = "k6",
    [keys.numPad7] = "k7",
    [keys.numPad8] = "k8",
    [keys.numPad9] = "k9",
    [keys.yen] = "\xa5",
    [keys.circumflex] = "^",
    [keys.at] = "@",
    [keys.colon] = ":",
    [keys.underscore] = "_",
}
local builtinKeyCharacters = {
    lt = "<",
    space = " ",
    backslash = "\\",
    bar = "|",
    kmultiply = "*",
    kplus = "+",
    kminus = "-",
    kpoint = ".",
    kequal = "=",
    kcomma = ",",
    kdivide = "/",
    k0 = "0",
    k1 = "1",
    k2 = "2",
    k3 = "3",
    k4 = "4",
    k5 = "5",
    k6 = "6",
    k7 = "7",
    k8 = "8",
    k9 = "9",
}
local modifierNames = {
    [keys.leftCtrl] = "C",
    [keys.rightCtrl] = "C",
    [keys.leftAlt] = "A",
    [keys.rightAlt] = "A",
    [keys.leftShift] = "S",
    [keys.rightShift] = "S",
}
local modifierOrder = {"C", "A", "S"}
local keyNormalisation = {
    ["<"] = "lt",
    -- [">"] = "gt",
    [" "] = "space",
    ["\\"] = "backslash",
    ["|"] = "bar",
    ["esc"] = "tab",
}
local mouseClickNames = {
    [1] = "leftmouse",
    [2] = "rightmouse",
    [3] = "middlemouse",
}

if not tab.find(args, "--term") then
    monitor = peripheral.find("monitor")
end

local function registerSimpleKeys(names)
    local _, k
    for _, k in ipairs(names) do
        if keys[k] == nil then
            error("No such key: " .. k)
        end
        keyNames[keys[k]] = k:lower()
    end
end
registerSimpleKeys{"left", "right", "up", "down"}
registerSimpleKeys{"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15"}
registerSimpleKeys{"home", "end", "pageUp", "pageDown", "insert"}
registerSimpleKeys{"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}

local function isCharacterKey(name)
    if #name == 1 then
        return true
    end
    if builtinKeyCharacters[name] ~= nil then
        return true
    end
    return false
end

local function getSelfInsert(name)
    if #name == 1 then
        return name
    end
    local ch = builtinKeyCharacters[name]
    if ch ~= nil then
        return ch
    end
    return "<" .. name .. ">"
end

local function registerAction(seq, cb)
    local key = keyseq.parseKeySequence(seq, keyNormalisation, modifierOrder)
    actionsTrie:put(key, cb)
end

local function registerActionMulti(components, getCb)
    for _, lst in itertools.product(components) do
        registerAction(table.concat(lst), getCb(lst))
    end
end

local function registerMapping(src, dst, opts)
    opts = opts or {}
    local srcArr = keyseq.parseKeySequence(src, keyNormalisation, modifierOrder)
    local dstArr = keyseq.parseKeySequence(dst, keyNormalisation, modifierOrder)
    local mode = opts.mode or ""
    if mode == "" then
        mode = "n"
    elseif mode == "!" then
        mode = "ic"
    end
    local remap = opts.remap or false
    local entry = {
        dst = dstArr,
        remap = remap,
    }
    for m in mode:gmatch(".") do
        local trie = modeMappings[m]
        if trie ~= nil then
            trie:put(srcArr, entry)
        end
    end
end

local function resetSize()
    if monitor then
        wid, hig = monitor.getSize()
    else
        wid, hig = term.getSize()
    end
end

local resetLastSearch

local function clear()
    if monitor then
        monitor.clear()
    else
        term.clear()
    end
end

local function setcolors(bg, txt)
    if monitor then
        monitor.setBackgroundColor(bg)
        monitor.setTextColor(txt)
    else
        term.setBackgroundColor(bg)
        term.setTextColor(txt)
    end
end

local function write(message)
    if monitor then
        monitor.write(message)
    else
        term.write(message)
    end
end

local function setpos(xpos, ypos)
    if monitor then
        monitor.setCursorPos(xpos, ypos)
    else
        term.setCursorPos(xpos, ypos)
    end
end

local function getLatestModifiers(...)  -- Example result: {A = true, C = nil}
    local result = {}
    local resetPrefixed = ... or false
    local k, v
    for k, v in pairs(activeModifiers) do
        if v then
            result[modifierNames[k]] = true
        end
    end
    for k, v in pairs(prefixedModifiers) do
        if v then
            result[modifierNames[k]] = true
            if resetPrefixed then
                prefixedModifiers[k] = nil
            end
        end
    end
    return result
end

local function insertTypeahead(charname, ...)
    local kwargs = ... or {}
    local update = kwargs.update or {}
    local index = kwargs.index or #typeahead + 1
    charname = keyseq.normalizeKey(charname, keyNormalisation, modifierOrder)
    table.insert(typeahead, index, charname)
    table.insert(typeaheadUpdates, index, update)
end

local function expandPaste(alwaysNoremap)
    local data = inputProperties.pasteData
    if not data then
        return
    end
    local noremap = alwaysNoremap or noremapFor > 0
    local length = 0
    for i, ch in itertools.enumerate(data:gmatch(".")) do
        insertTypeahead(ch, {index = i})
        length = i
    end
    if noremap then
        noremapFor = noremapFor + length
    end
end

local handleNonInputEvent  -- implemented after dependencies are declared

local function waitForEvents()
    local e, s, v2, v3 = os.pullEvent()
    if e == "char" then
        local mods = getLatestModifiers(true)
        if mods.S then
            -- Do not add shift, because it should already be consumed by the key to char conversion
        end
        if mods.A then
            -- Warning: AltGr might generate unwanted alt modification
            s = "A-" .. s
        end
        if mods.C then
            s = "C-" .. s
        end
        insertTypeahead(s)
    elseif e == "key" then
        local translatedKey = keyNames[s]
        local translatedMod = modifierNames[s]
        if translatedKey ~= nil then
            translatedKey = keyNormalisation[translatedKey:lower()] or translatedKey
            -- Only if the key event will not be doubled by a char event
            if not isCharacterKey(translatedKey) or activeModifiers[keys.leftCtrl] or activeModifiers[keys.rightCtrl] then
                local mods = getLatestModifiers(true)
                if mods.S then
                    translatedKey = "S-" .. translatedKey
                end
                if mods.A then
                    translatedKey = "A-" .. translatedKey
                end
                if mods.C then
                    translatedKey = "C-" .. translatedKey
                end
                insertTypeahead(translatedKey)
            end
        elseif translatedMod ~= nil then
            activeModifiers[s] = true
            if prefixedModifiers[s] then
                prefixedModifiers[s] = nil  -- Repeated modifier presses remove the prefixed state
            else
                prefixedModifiers[s] = not v2  -- Only prefixed if not held
                -- FIXME repeats for the modifier keys seem to not be sent
            end
        end
    elseif e == "key_up" then
        local translatedMod = modifierNames[s]
        if translatedMod ~= nil then
            activeModifiers[s] = nil  -- No longer active
            -- But remain prefixed
        end
    elseif e == "mouse_click" then
        local translatedKey = mouseClickNames[s]
        local mods = getLatestModifiers(true)
        if mobile or translatedKey == nil then
            translatedKey = "tab"
        else
            if mods.S then
                translatedKey = "S-" .. translatedKey
            end
            if mods.A then
                translatedKey = "A-" .. translatedKey
            end
            if mods.C then
                translatedKey = "C-" .. translatedKey
            end
        end
        insertTypeahead(translatedKey, {update = {mouseX = v2, mouseY = v3}})
    elseif e == "mouse_scroll" then
        local translatedKey = "scrollwheeldown"
        if s < 0 then
            translatedKey = "scrollwheelup"
        end
        local mods = getLatestModifiers(true)
        if mods.S then
            translatedKey = "S-" .. translatedKey
        end
        if mods.A then
            translatedKey = "A-" .. translatedKey
        end
        if mods.C then
            translatedKey = "C-" .. translatedKey
        end
        insertTypeahead(translatedKey, {update = {mouseX = v2, mouseY = v3}})
    elseif e == "paste" then
        local translatedKey = "C-v"
        local mods = getLatestModifiers(true)
        if mods.S then
            translatedKey = "S-" .. translatedKey
        end
        if mods.A then
            translatedKey = "A-" .. translatedKey
        end
        insertTypeahead(translatedKey, {update = {pasteData = s}})
    else
        handleNonInputEvent(e, s, v2, v3)
    end
end

local function pullTypeahead()
    local key = table.remove(typeahead, 1)
    while key == nil and running do
        waitForEvents()
        key = table.remove(typeahead, 1)
    end
    local upd = table.remove(typeaheadUpdates, 1)
    itertools.update(inputProperties, upd)
    if noremapFor > 0 then
        noremapFor = noremapFor - 1
    end
    return key
end

local applyMappings

-- pull from typeahead with remaps
local function pullTypeaheadWRMP()
    applyMappings()
    local key = pullTypeahead()
    return key
end

local function peekTypeahead(idx)
    idx = idx or 1
    while #typeahead < idx do
        waitForEvents()
    end
    return typeahead[idx]
end

local function peekTypeaheadWRMP(idx)
    applyMappings()
    local key = peekTypeahead(idx)
    return key
end

local function typeaheadLength()
    return #typeahead
end

function applyMappings()
    while noremapFor < 1 do
        local trie = modeMappings[currentMode]
        if trie == nil then
            return
        end
        local i = 0
        local cons = trie:consumer()
        while true do
            i = i + 1
            local key = peekTypeahead(i)
            if not cons:next(key) then
                break
            end
            if not cons:hasNext() then
                break
            end
        end
        local len, entry = cons:getDeepest()
        if len > 0 then
            local dst = entry.dst or {}
            if #dst < 1 then
                for _ = 1, len do
                    pullTypeahead()
                end
            else
                local saveProps = inputProperties
                inputProperties = {}
                for _ = 1, len do
                    pullTypeahead()
                end
                local squashedUpdate = inputProperties
                inputProperties = saveProps
                insertTypeahead(dst[1], {update = squashedUpdate, index = 1})
                for i = 2, #dst do
                    insertTypeahead(dst[i], {index = i})
                end
                if not entry.remap then
                    noremapFor = #dst
                end
            end
        else
            noremapFor = 1
        end
    end
end

local function pullCount()  -- Returns string
    local ch = peekTypeaheadWRMP(1)
    while ch == "<C-S-v>" do
        pullTypeahead()
        expandPaste()
        ch = peekTypeaheadWRMP()
    end
    if ch:find("[^1-9]") then
        return ""
    end
    pullTypeahead()
    local builder = {ch}
    while true do
        ch = peekTypeaheadWRMP(1)
        while ch == "<C-S-v>" do
            pullTypeahead()
            expandPaste()
            ch = peekTypeaheadWRMP()
        end
        if ch:find("%D") then
            return table.concat(builder)
        end
        pullTypeahead()
        table.insert(builder, ch)
    end
end

local function pullCommand(input, numeric, len)
    if input == nil then
        input = ''
    end
    local x,y = 1, hig
    local oldModeMsg = modeMsg
    local prevMode = currentMode
    currentMode = "c"

    local backspace = false
    local finish = false
  
    repeat
        setcolors(colors.black, colors.white)
        setpos(x,y)
        write(input)
        if backspace then
            write("  ")
            resetSize()
            setpos(x - 1, y)
            if #input < 1 then
                finish = true
                insertTypeahead("bs", {index = 1})  -- Insert fake event to consume
            end
        end
        if #input > 0 then
            setpos(x + #input, y)
            setcolors(colors.lightGray, colors.white)
            write(" ")
        end
  
        modeMsg = input
        local key = pullTypeaheadWRMP()
        -- terminal cursor position is undefined after typeahead access
        y = hig
        setpos(x + #input, y)
  
        if isCharacterKey(key) then
            local p1 = getSelfInsert(key)
            local send = true
            if #input < 1 then
                setpos(1, 1)
                setcolors(colors.black, colors.white)
                write(" ")
            end
            if numeric and tonumber(p1) == nil then
                send = false
            end
            if len ~= nil then
                if (#input < len) and send then
                    input = input .. p1
                end
            else
                if send then
                    input = input .. p1
                end
            end
        elseif not finish then
            if key == "bs" then
                input = input:sub(1, #input - 1)
                backspace = true
            elseif key == "C-S-v" then
                expandPaste()
            end
        end
    until (key == "cr") or (finish == true)
    modeMsg = oldModeMsg
    currentMode = prevMode
    return input
end

local function clearScreenLine(line)
    setcolors(colors.black, colors.white)
    setpos(1, line)
    for i=1,wid,1 do
        write(" ")
    end
end

local function err(message)
    clearScreenLine(hig)
    setpos(1, hig)
    setcolors(colors.red, colors.white)
    write(message)
end

local function sendMsg(message)
    clearScreenLine(hig)
    setpos(1, hig)
    setcolors(colors.black, colors.white)
    write(message)
end

local function setModeMsg(msg)
    if msg and #msg > 0 then
        modeMsg = msg
        sendMsg(msg)
    else
        modeMsg = nil
        sendMsg(" ")
    end
end

local function drawFile(forcedredraw)
    motd = false
    if currXOffset ~= oldXOffset or currFileOffset ~= oldFileOffset or forcedredraw then
        for i=1,hig-1,1 do
            clearScreenLine(i)
        end
        oldXOffset = currXOffset
        oldFileOffset = currFileOffset
        for i=currFileOffset,(hig - 1) + currFileOffset,1 do
            setpos(1, i - currFileOffset)
            if filelines then
                if filelines[i] ~= nil then
                    setcolors(colors.black, colors.white)
                    if fileContents[currfile] then
                        if fileContents[currfile]["filetype"] and syntaxhighlighting and filetypearr[fileContents[currfile]["filetype"]] then
                            local synt = filetypearr[fileContents[currfile]["filetype"]].syntax()
                            local wordsOfLine = str.split(filelines[i], " ")
                            setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                            for j=1,#wordsOfLine,1 do
                                if tab.find(synt[1], wordsOfLine[j]) then
                                    setcolors(colors.yellow, colors.blue)
                                elseif tab.find(synt[2][1], wordsOfLine[j]) then
                                    setcolors(colors.black, colors.lightBlue)
                                elseif tab.find(synt[2][2], wordsOfLine[j]) then
                                    setcolors(colors.black, colors.purple)
                                else
                                    setcolors(colors.black, colors.white)
                                end
                                write(wordsOfLine[j])
                                if j ~= #wordsOfLine then
                                    setcolors(colors.black, colors.white)
                                    write(" ")
                                end
                            end
                            --another loop for drawing strings
                            setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                            local quotationmarks = str.indicesOfLetter(filelines[i], synt[3])
                            local inquotes = false
                            local justset = false
                            local quotepoints = {}
                            setcolors(colors.black, colors.red)
                            for j=1,#filelines[i],1 do
                                local writechar = not ((1 - currXOffset - lineoffset + j - 1 < 1) or (1 - currXOffset + lineoffset + j - 1 > wid))
                                if writechar then
                                    setpos(1 - currXOffset + lineoffset + j - 1, i - currFileOffset)
                                end
                                if tab.find(quotationmarks, j) then
                                    if not inquotes then
                                        if j < quotationmarks[#quotationmarks] then
                                            inquotes = true
                                            justset = true
                                        end
                                    end
                                end
                                if inquotes then
                                    if writechar then
                                        write(string.sub(filelines[i], j, j))
                                    end
                                    table.insert(quotepoints, #quotepoints, j - 2) --Don't know why I need to subtract 2 but heck it works
                                end
                                if tab.find(quotationmarks, j) and not justset then
                                    if inquotes then
                                        inquotes = false
                                    end
                                end
                                justset = false
                            end
                            local commentstart = 0
                            commentstart = str.find(filelines[i], synt[4], quotepoints)
                            if commentstart and commentstart ~= false then
                                setpos(1 - currXOffset + lineoffset + commentstart - 1, i - currFileOffset)
                                setcolors(colors.black, colors.green)
                                write(string.sub(filelines[i], commentstart, #filelines[i]))
                            end
                            commentstart = str.find(filelines[i], synt[7][2])
                            if not commentstart then
                                commentstart = 0
                            end
                            if not lowspec then
                                if tab.find(fileContents[currfile]["Multi-line comments"][2], i) then
                                    setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                    setcolors(colors.black, colors.green)
                                    write(filelines[i])
                                elseif tab.find(fileContents[currfile]["Multi-line comments"][3], i) then
                                    setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                    setcolors(colors.black, colors.green)
                                    write(string.sub(filelines[i], 1, commentstart + 1))
                                end
                            end
                        else
                            setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                            write(string.sub(filelines[i], 1, #filelines[i]))
                        end
                    end
                else
                    setcolors(colors.black, colors.purple)
                    write("~")
                end
            end
        end
    else
        --only draw 3 lines
        for i=currCursorY + currFileOffset - 1, currCursorY + currFileOffset + 2, 1 do
            if i - currFileOffset < hig then
                clearScreenLine(i - currFileOffset)
                setpos(1, i - currFileOffset)
                if filelines then
                    if filelines[i] ~= nil then
                        setcolors(colors.black, colors.white)
                        if fileContents[currfile] then
                            if fileContents[currfile]["filetype"] and syntaxhighlighting and filetypearr[fileContents[currfile]["filetype"]] then
                                local synt = filetypearr[fileContents[currfile]["filetype"]].syntax()
                                local wordsOfLine = str.split(filelines[i], " ")
                                setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                for j=1,#wordsOfLine,1 do
                                    if tab.find(synt[1], wordsOfLine[j]) then
                                        setcolors(colors.yellow, colors.blue)
                                    elseif tab.find(synt[2][1], wordsOfLine[j]) then
                                        setcolors(colors.black, colors.lightBlue)
                                    elseif tab.find(synt[2][2], wordsOfLine[j]) then
                                        setcolors(colors.black, colors.purple)
                                    else
                                        setcolors(colors.black, colors.white)
                                    end
                                    write(wordsOfLine[j])
                                    if j ~= #wordsOfLine then
                                        setcolors(colors.black, colors.white)
                                        write(" ")
                                    end
                                end
                                --another loop for drawing strings
                                setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                local quotationmarks = str.indicesOfLetter(filelines[i], synt[3])
                                local inquotes = false
                                local justset = false
                                local quotepoints = {}
                                setcolors(colors.black, colors.red)
                                for j=1,#filelines[i],1 do
                                    local writechar = not ((1 - currXOffset - lineoffset + j - 1 < 1) or (1 - currXOffset + lineoffset + j - 1 > wid))
                                    if writechar then
                                        setpos(1 - currXOffset + lineoffset + j - 1, i - currFileOffset)
                                    end
                                    if tab.find(quotationmarks, j) then
                                        if not inquotes then
                                            if j < quotationmarks[#quotationmarks] then
                                                inquotes = true
                                                justset = true
                                            end
                                        end
                                    end
                                    if inquotes then
                                        if writechar then
                                            write(string.sub(filelines[i], j, j))
                                        end
                                        table.insert(quotepoints, #quotepoints, j - 2)
                                    end
                                    if tab.find(quotationmarks, j) and not justset then
                                        if inquotes then
                                            inquotes = false
                                        end
                                    end
                                    justset = false
                                end
                                local commentstart = 0
                                commentstart = str.find(filelines[i], synt[4], quotepoints)
                                if commentstart and commentstart ~= false then
                                    setpos(1 - currXOffset + lineoffset + commentstart - 1, i - currFileOffset)
                                    setcolors(colors.black, colors.green)
                                    write(string.sub(filelines[i], commentstart, #filelines[i]))
                                end
                                commentstart = str.find(filelines[i], synt[7][2])
                                if not commentstart then
                                    commentstart = 0
                                end
                                if not lowspec then
                                    if tab.find(fileContents[currfile]["Multi-line comments"][2], i) then
                                        setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                        setcolors(colors.black, colors.green)
                                        write(filelines[i])
                                    elseif tab.find(fileContents[currfile]["Multi-line comments"][3], i) then
                                        setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                        setcolors(colors.black, colors.green)
                                        write(string.sub(filelines[i], 1, commentstart + 1))
                                    end
                                end
                            else
                                setpos(1 - currXOffset + lineoffset, i - currFileOffset)
                                write(string.sub(filelines[i], 1, #filelines[i]))
                            end
                        end
                    else
                        setcolors(colors.black, colors.purple)
                        write("~")
                    end
                end
            end
        end
    end
    -- Draw the cursor
    local tmp
    if filelines then
        if filelines[currCursorY + currFileOffset] ~= nil then
            tmp = string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset)
        end
    end
    if filelines then
        setpos(currCursorX + lineoffset, currCursorY)
    else
        setpos(currCursorX, currCursorY)
    end
    setcolors(colors.lightGray, colors.white)
    if tmp ~= nil and tmp ~= "" then
        write(tmp)
    else
        write(" ")
    end
    if linenumbers then
        setcolors(colors.black, colors.yellow)
        for i=currFileOffset,(hig-1)+currFileOffset,1 do
            setpos(1, i - currFileOffset)
            if i < 1000 then
                write(string.rep(" ", 3 - #tostring(i)))
            end
            if i < 10000 then
                if i <= #filelines then
                    write(i)
                end
            else
                if i <= #filelines then
                    write("10k+")
                end
            end
        end
    end
end

local function moveCursorLeft()
    lastSearchPos = nil
    lastSearchLine = nil
    if currCursorX + currXOffset ~= 1 then
        currCursorX = currCursorX - 1
        if currCursorX < 1 then
            currCursorX = currCursorX + 1
            currXOffset = currXOffset - 1
            drawFile(true)
        else
            drawFile()
        end
    end
    oldx = nil
end

local function moveCursorRight(endPad)
    lastSearchPos = nil
    lastSearchLine = nil
    if endPad == nil then
        endPad = 0
    end
    if filelines[currCursorY + currFileOffset] ~= nil then
        if currCursorX + currXOffset < #(filelines[currCursorY + currFileOffset]) + 1 - endPad then
            currCursorX = currCursorX + 1
            if currCursorX + lineoffset > wid then
                currCursorX = currCursorX - 1
                currXOffset = currXOffset + 1
                drawFile(true)
            else
                drawFile()
            end
        end
    end
    oldx = nil
end

local function moveCursorUp(ignoreX)
    lastSearchPos = nil
    lastSearchLine = nil
    if oldx ~= nil and not ignoreX then
        currCursorX = oldx - currXOffset
    else
        oldx = currCursorX + currXOffset
    end
    if currCursorY + currFileOffset ~= 1 then
        currCursorY = currCursorY - 1
        if currCursorX + currXOffset > #(filelines[currCursorY + currFileOffset]) + 1 then
            if filelines[currCursorY + currFileOffset] ~= "" then
                currCursorX = #(filelines[currCursorY + currFileOffset]) + 1 - currXOffset
            else
                currCursorX = 1
                currXOffset = 0
            end
        end
        if currCursorX < 1 then
            while currCursorX < 1 do
                currXOffset = currXOffset - 1
                currCursorX = currCursorX + 1
            end
        elseif currCursorX + lineoffset > wid then
            while currCursorX + lineoffset > wid do
                currXOffset = currXOffset + 1
                currCursorX = currCursorX - 1
            end
        end
        while currCursorY < 1 do
            currFileOffset = currFileOffset - 1
            currCursorY = currCursorY + 1
        end
        while currFileOffset < 0 do
            currFileOffset = currFileOffset + 1
        end
        drawFile()
    end
end

local function moveCursorDown()
    lastSearchPos = nil
    lastSearchLine = nil
    if oldx ~= nil then
        currCursorX = oldx - currXOffset
    else
        oldx = currCursorX + currXOffset
    end
    if currCursorY + currFileOffset < #filelines then
        currCursorY = currCursorY + 1
        if currCursorX + currXOffset > #(filelines[currCursorY + currFileOffset]) + 1 then
            if filelines[currCursorY + currFileOffset] ~= "" then
                currCursorX = #(filelines[currCursorY + currFileOffset]) + 1 - currXOffset
            else
                currCursorX = 1
                currXOffset = 0
            end
        end
        if currCursorX < 1 then
            while currCursorX < 1 do
                currXOffset = currXOffset - 1
                currCursorX = currCursorX + 1
            end
        elseif currCursorX + lineoffset > wid then
            while currCursorX + lineoffset > wid do
                currXOffset = currXOffset + 1
                currCursorX = currCursorX - 1
            end
        end
        while currCursorY > hig - 1 do
            currFileOffset = currFileOffset + 1
            currCursorY = currCursorY - 1
        end
        drawFile()
    end
end

local function scrollWindowY(amount, currSOL)
    resetLastSearch()
    if not currSOL then
        if oldx ~= nil then
            currCursorX = oldx - currXOffset
        else
            oldx = currCursorX + currXOffset
        end
    end
    if amount == 0 then
        return
    end
    currFileOffset = currFileOffset + amount
    if amount < 0 then
        if currFileOffset < 0 then
            currCursorY = currCursorY + currFileOffset
            currFileOffset = 0
            if currCursorY < 1 then
                currCursorY = 1
            end
        end
    else
        if currCursorY + currFileOffset > #filelines then
            currCursorY = #filelines - currFileOffset
            if currCursorY < 1 then
                currFileOffset = currFileOffset + currCursorY - 1
                currCursorY = 1
                if currFileOffset < 0 then
                    currFileOffset = 0
                end
            end
        end
    end
    if currSOL then
        currCursorX = 1
        currXOffset = 0
    else
        local line = filelines[currCursorY + currFileOffset]
        if line and #line < currCursorX + currXOffset then
            currCursorX = #line - currXOffset
            if currCursorX < 1 then
                currXOffset = currXOffset + currCursorX - 1
                currCursorX = 1
                if currXOffset < 0 then
                    currXOffset = 0
                end
            end
        end
    end
    drawFile(true)
end

--Recalculate where multi-line comments are, based on position in file
local function recalcMLCs(force, offsetby)
    if not fileContents[currfile] then
        return
    end
    if not fileContents[currfile]["Multi-line comments"] then
        fileContents[currfile]["Multi-line comments"] = {{}, {}, {}}
    end
    if not lowspec then
        local synt
        if fileContents[currfile]["filetype"] then
            if fs.exists("/vim/syntax/"..fileContents[currfile]["filetype"]..".lua")then
                local tmp = require("/vim/syntax/"..fileContents[currfile]["filetype"])
                synt = tmp.syntax()
            end
        end
        if synt then
            if offsetby then
                --move all multi-line comments after the current cursor Y by offsetby
                for i=1,#fileContents[currfile]["Multi-line comments"][1],1 do
                    if fileContents[currfile]["Multi-line comments"][1][i] > currCursorY + currFileOffset + offsetby[1] then
                        fileContents[currfile]["Multi-line comments"][1][i] = fileContents[currfile]["Multi-line comments"][1][i] + offsetby[2]
                    end
                end
                for i=1,#fileContents[currfile]["Multi-line comments"][2],1 do
                    if fileContents[currfile]["Multi-line comments"][2][i] > currCursorY + currFileOffset + offsetby[1] then
                        fileContents[currfile]["Multi-line comments"][2][i] = fileContents[currfile]["Multi-line comments"][2][i] + offsetby[2]
                    end
                end
                for i=1,#fileContents[currfile]["Multi-line comments"][3],1 do
                    if fileContents[currfile]["Multi-line comments"][3][i] > currCursorY + currFileOffset + offsetby[1] then
                        fileContents[currfile]["Multi-line comments"][3][i] = fileContents[currfile]["Multi-line comments"][3][i] + offsetby[2]
                    end
                end
                if tab.find(fileContents[currfile]["Multi-line comments"][2], currCursorY + currFileOffset - 1) then
                    --if the cursor - 1 is on a multi-line comment (type 2), then check if the current line contains the end of the comment.
                    --if it does, add it as type 3. If not, add it as type 2.
                    if str.find(fileContents[currfile][currCursorY + currFileOffset], "]]") then
                        table.insert(fileContents[currfile]["Multi-line comments"][3], currCursorY + currFileOffset)
                    else
                        table.insert(fileContents[currfile]["Multi-line comments"][2], currCursorY + currFileOffset)
                    end
                end
            else
                if ((tab.find(fileContents[currfile]["Multi-line comments"][1], currCursorY + currFileOffset) and not str.find(filelines[currCursorY + currFileOffset], synt[7][1])) or (not tab.find(fileContents[currfile]["Multi-line comments"][1], currCursorY + currFileOffset) and str.find(filelines[currCursorY + currFileOffset], synt[7][1])) or (tab.find(fileContents[currfile]["Multi-line comments"][3], currCursorY + currFileOffset) and not str.find(filelines[currCursorY + currFileOffset], synt[7][2])) or (not tab.find(fileContents[currfile]["Multi-line comments"][3], currCursorY + currFileOffset) and str.find(filelines[currCursorY + currFileOffset], synt[7][2])) or force) and syntaxhighlighting then
                    local multilinesInFile = {{}, {}, {}} --beginning quote points, regular quote points, end quote points
                    local quotepoints = {}
                    local justset = false
                    for j=1,#fileContents[currfile],1 do
                        local quotationmarks = str.indicesOfLetter(fileContents[currfile][j], synt[3])
                        local inquotes = false
                        justset = false
                        for k=1,#fileContents[currfile][j],1 do
                            if tab.find(quotationmarks, k) then
                                if not inquotes then
                                    if k < quotationmarks[#quotationmarks] then
                                        inquotes = true
                                        justset = true
                                    end
                                end
                            end
                            if inquotes then
                                table.insert(quotepoints, #quotepoints, k - 2)
                            end
                            if tab.find(quotationmarks, k) and not justset then
                                if inquotes then
                                    inquotes = false
                                end
                            end
                            justset = false
                        end
                    end
                    local inmulti = false
                    justset = false
                    for j=1,#fileContents[currfile],1 do
                        if str.find(fileContents[currfile][j], synt[7][1], quotepoints) and not inmulti then
                            inmulti = true
                            justset = true
                            table.insert(multilinesInFile[1], #multilinesInFile[1] + 1, j)
                        end
                        if inmulti and not (str.find(fileContents[currfile][j], synt[7][2])) and not justset then
                            table.insert(multilinesInFile[2], #multilinesInFile[2] + 1, j)
                        end
                        if str.find(fileContents[currfile][j], synt[7][2]) then
                            if inmulti then
                                inmulti = false
                                table.insert(multilinesInFile[3], #multilinesInFile[3] + 1, j)
                            end
                        end
                        justset = false
                    end
                    fileContents[currfile]["Multi-line comments"] = multilinesInFile
                    return true
                else
                    return false
                end
            end
        end
    else
        return false
    end
end

local function redrawTerm()
    clearScreenLine(hig)
    if motd then
        clear()
        for i=currFileOffset,(hig - 1) + currFileOffset,1 do
            setpos(1, i - currFileOffset)
            setcolors(colors.black, colors.purple)
            write("~")
        end
        setcolors(colors.black, colors.white)
        setpos((wid / 2) - (33 / 2), (hig / 2) - 3)
        write("CCVIM - ComputerCraft Vi Improved")
        setpos((wid / 2) - (#("version ".. version) / 2), (hig / 2) - 1)
        write("version "..version)
        setpos((wid / 2) - (13 / 2), (hig / 2))
        write("By Minater247")
        if wid > 53 then
            setpos((wid / 2) - (46 / 2), (hig / 2) + 1)
            write("CCVIM is open source and freely distributable.")
            setpos((wid / 2) - (28 / 2), (hig / 2) + 4)
        else
            setpos((wid / 2) - (28 / 2), (hig / 2) + 3)
        end
        write("Type :q")
        setcolors(colors.black, colors.lightBlue)
        write("<Enter>       ")
        setcolors(colors.black, colors.white)
        write("to exit")
    else
        drawFile(true)
    end
    while currCursorX + lineoffset > wid do
        currCursorX = currCursorX - 1
        currXOffset = currXOffset + 1
    end
    while currCursorX < 1 do
        currCursorX = currCursorX + 1
        currXOffset = currXOffset - 1
    end
    while currCursorY > hig - 1 do
        currCursorY = currCursorY - 1
        currFileOffset = currFileOffset + 1
    end
    while currCursorY < 1 do
        currCursorY = currCursorY + 1
        currFileOffset = currFileOffset - 1
    end
end

-- declared above
function handleNonInputEvent(e, s, v2, v3)
    if e == "term_resize" then
        resetSize()
        redrawTerm()
        if modeMsg ~= nil then
            sendMsg(modeMsg)
        end
    end
end

local function insertMode()
    drawFile(true)
    setModeMsg("-- INSERT --")
    local prevMode = currentMode
    currentMode = "i"
    local key
    while key ~= "tab" do
        key = pullTypeaheadWRMP()
        if not isCharacterKey(key) and key ~= "C-v" then
            if key == "left" then
                moveCursorLeft()
            elseif key == "right" then
                moveCursorRight()
            elseif key == "up" then
                moveCursorUp()
            elseif key == "down" then
                moveCursorDown()
            elseif key == "C-S-v" then
                expandPaste(true)
            elseif key == "bs" then
                if filelines[currCursorY + currFileOffset] ~= "" and filelines[currCursorY + currFileOffset] ~= nil and currCursorX > 1 then
                    filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 2) .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #(filelines[currCursorY + currFileOffset]))
                    moveCursorLeft()
                    local redrawhere = recalcMLCs()
                    fileContents[currfile]["unsavedchanges"] = true
                    drawFile(redrawhere)
                else
                    if currCursorX + currXOffset < 2 then
                        if currCursorY + currFileOffset > 1 then
                            if #filelines > 1 then
                                currCursorX = #(filelines[currCursorY + currFileOffset - 1]) + 1
                                filelines[currCursorY + currFileOffset - 1] = filelines[currCursorY + currFileOffset - 1] .. filelines[currCursorY + currFileOffset]
                                table.remove(filelines, currCursorY + currFileOffset)
                                moveCursorUp(true)
                                if currCursorX + lineoffset > wid then
                                    while currCursorX + lineoffset > wid do
                                        currXOffset = currXOffset + 1
                                        currCursorX = currCursorX - 1
                                    end
                                end
                                recalcMLCs()
                                drawFile(true)
                                fileContents[currfile]["unsavedchanges"] = true
                            end
                        end
                    else
                        filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 2) .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #(filelines[currCursorY + currFileOffset]))
                        currXOffset = currXOffset - math.floor(wid / 2)
                        currCursorX = currCursorX + math.floor(wid / 2) - 1
                        if currXOffset < 0 then
                            currCursorX = currXOffset + currCursorX
                            currXOffset = 0
                        end
                        local redrawhere = recalcMLCs()
                        drawFile(redrawhere)
                        fileContents[currfile]["unsavedchanges"] = true
                        lastSearchPos = nil
                        lastSearchLine = nil
                    end
                end
            elseif key == "cr" then
                lastSearchPos = nil
                lastSearchLine = nil
                if filelines[currCursorY + currFileOffset] ~= nil then
                    local indentedamount = 0
                    if autoindent then
                        --check if current line is indented, if so, indent the new line
                        for i=1,#(filelines[currCursorY + currFileOffset]),1 do
                            if string.sub(filelines[currCursorY + currFileOffset], i, i) == " " then
                                indentedamount = indentedamount + 1
                            else
                                break
                            end
                        end
                    end
                    table.insert(filelines, currCursorY + currFileOffset + 1, string.rep(" ", indentedamount) .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #(filelines[currCursorY + currFileOffset])))
                    filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1)
                    currCursorY = currCursorY + 1
                    while currCursorY > hig - 1 do
                        currFileOffset = currFileOffset + 1
                        currCursorY = currCursorY - 1
                    end
                    currCursorX = 1
                    currXOffset = 0
                    for i=1,indentedamount,1 do
                        currCursorX = currCursorX + 1
                        while currCursorX + lineoffset > wid do
                            currXOffset = currXOffset + 1
                            currCursorX = currCursorX - 1
                        end
                        if currXOffset < 0 then
                            currXOffset = 0
                        end
                    end
                    fileContents[currfile]["unsavedchanges"] = true
                else
                    table.insert(filelines, currCursorY + currFileOffset + 1, "")
                end
                recalcMLCs(false, {-1, 1}) --slow, but it works for now
                drawFile(true)
            end
        else
            lastSearchPos = nil
            lastSearchLine = nil
            if filelines[currCursorY + currFileOffset] == nil then
                filelines[currCursorY + currFileOffset] = ""
            end
            local ch
            if key == "C-v" then
                local rawKey = pullTypeahead()
                if rawKey == "x" then
                    local valid = true
                    local charCode = 0
                    for _ = 1, 2 do
                        local nibbleChar = pullTypeahead()
                        if not nibbleChar:find("^[0-9A-Fa-f]$") then
                            valid = false
                            break
                        end
                        local nibbleNum
                        if nibbleChar:find("[A-F]") then
                            nibbleNum = nibbleChar:byte() - ("A"):byte() + 10
                        elseif nibbleChar:find("[a-f]") then
                            nibbleNum = nibbleChar:byte() - ("a"):byte() + 10
                        else
                            nibbleNum = nibbleChar:byte() - ("0"):byte()
                        end
                        charCode = charCode * 16 + nibbleNum
                    end
                    if valid then
                        ch = string.char(charCode)
                    else
                        ch = ""
                    end
                else
                    ch = getSelfInsert(rawKey)
                end
            else
                ch = getSelfInsert(key)
            end
            if ch == "\n" then
                ch = ""
                insertTypeahead("cr", {index = 1})
            end
            filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1) .. ch ..string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #(filelines[currCursorY + currFileOffset]))
            currCursorX = currCursorX + #ch
            while currCursorX + lineoffset > wid do
                currCursorX = currCursorX - 1
                currXOffset = currXOffset + 1
            end
            local redrawhere = recalcMLCs()
            drawFile(redrawhere)
            if not fileContents[currfile] then
                fileContents[currfile] = {""}
            end
            fileContents[currfile]["unsavedchanges"] = true
        -- mouse_click was already translated to tab by the pullTypeahead
        end
    end
    setModeMsg(nil)
    currentMode = prevMode
end

--Parse .vimrc file here
if fs.exists("/vim/.vimrc") then
    local vimrclines = fil.toArr("/vim/.vimrc")
    for i=1,#vimrclines,1 do
        if not (string.sub(vimrclines[i], 1, 1) == "\"") then --ignore commented lines
            local rctable = str.split(vimrclines[i], " ")
            if rctable[1] == "set" then
                if not string.find(rctable[2], "=") then
                    if rctable[2] == "mobile" then
                        mobile = true
                    elseif rctable[2] == "number" then
                        linenumbers = true
                        lineoffset = 4
                    elseif rctable[2] == "lowperformance" then
                        lowspec = true
                    elseif rctable[2] == "autoindent" then
                        autoindent = true
                    elseif rctable[2] == "ignorecase" or rctable[2] == "ic" then
                        ignorecase = true
                    end
                else
                    --set the things to values
                end
            elseif rctable[1] == "syntax" and rctable[2] == "on" then
                syntaxhighlighting = true
            elseif mappingCommands[rctable[1]] ~= nil then
                if rctable[2] and rctable[3] or not (#rctable > 3) then
                    local opts = mappingCommands[rctable[1]]
                    registerMapping(rctable[2], rctable[3], opts)
                else
                    print("Mapping requires 2 arguments.")
                    sendMsg("Press enter to continue...")
                    local _,k = os.pullEvent("key")
                    while k ~= keys.enter do
                        _,k = os.pullEvent("key")
                    end
                end
            elseif rctable[1] == "finish" then
                break
            elseif rctable[1] ~= "" and rctable[1] ~= nil then
                error("Unrecognized vimrc command " .. rctable[1] .. ". Full vimscript is not yet supported.")
            end
        end
    end
end

local function pullChar()
    local _, tm = os.pullEvent("char")
    return _, tm
end

local function pullTypeaheadChar()
    local ch
    repeat
        local key = pullTypeaheadWRMP()
        if key == "C-S-v" then
            expandPaste()
        end
        ch = getSelfInsert(key)
    until #ch == 1
    return ch
end

local function pullTypeaheadCharMode(mode)
    local prevMode = currentMode
    currentMode = mode
    local ch = pullTypeaheadChar()
    currentMode = prevMode
    return ch
end

local oldyoff
local function drawDirInfo(dir, sortType, ypos, yoff, filesInDir, initialDraw)
    if initialDraw then
        setcolors(colors.black, colors.white)
        for i=1,hig-1,1 do
            clearScreenLine(i)
        end
        setpos(1, 1)
        write("\" ")
        for i=1,wid - 4,1 do
            write("=")
        end
        setpos(1, 2)
        write("\" CCFXP Directory Listing")
        for i=1,wid-25,1 do
            write(" ")
        end
        setpos(wid-#tostring(fileExplorerVer)-6, 2)
        write("ver. "..fileExplorerVer)
        setpos(1, 5)
        write("\"   Quick Help: -:go up dir  D:delete  R:rename  s:sort-by")
        for i=1,wid-#("\"   Quick Help: -:go up dir  D:delete  R:rename  s:sort-by"),1 do
            write(" ")
        end
    end
    for i=1,wid-#("\"   "..shell.resolve(dir)),1 do
        write(" ")
    end
    setpos(1, 3)
    write("\"   "..shell.resolve(dir))
    if fs.isDir(shell.resolve(dir)) then
        write("/")
    end
    clearScreenLine(4)
    setpos(1, 4)
    write("\"   Sorted by    ")
    write(sortType)
    for i=1,wid-#("\"   Sorted by    "..sortType),1 do
        write(" ")
    end
    setpos(1, 6)
    setcolors(colors.black, colors.white)
    write("\" ")
    for i=1,wid - 2,1 do
        write("=")
    end
    if oldyoff ~= yoff or initialDraw then
        for i=1+yoff,hig - 7 + yoff,1 do
            clearScreenLine(6+i - yoff)
            setpos(1, 6+i - yoff)
            if i - yoff == ypos then
                setcolors(colors.lightGray, colors.white)
            else
                setcolors(colors.black, colors.white)
            end
            if 6 + i - yoff < hig then
                if filesInDir[i] then
                    write(filesInDir[i])
                    if fs.isDir(dir .. "/" .. filesInDir[i]) then
                        write("/")
                    end
                else
                    setcolors(colors.black, colors.purple)
                    write("~")
                    setcolors(colors.black, colors.white)
                end
            end
        end
        setcolors(colors.black, colors.white)
        oldyoff = yoff
    else
        for i=-1,1,1 do
            setpos(1, 6 + ypos + i)
            if i == 0 then
                setcolors(colors.lightGray, colors.white)
            else
                setcolors(colors.black, colors.white)
            end
            if 6 + ypos + i > 6 and 6 + ypos + i < hig then
                if filesInDir[ypos + yoff + i] then
                    write(filesInDir[ypos + yoff + i])
                    if fs.isDir(dir .. "/" .. filesInDir[ypos + yoff + i]) then
                        write("/")
                    end
                else
                    setcolors(colors.black, colors.purple)
                    write("~")
                    setcolors(colors.black, colors.white)
                end
            end
        end
        setcolors(colors.black, colors.white)
    end
end

-- Directory opener.
-- Make sure the path is passed through fil.path() before coming to this function.
-- Display name can be passed to inputname, but is optional.
local function dirOpener(dir, inputname)
    local currSelection = dir.."/"
    if inputname then
        sendMsg("\"/"..shell.resolve(inputname).."/\" is a directory")
    else
        sendMsg("\"/"..shell.resolve(dir).."/\" is a direcotry")
    end
    local sortType = "name"
    local currDirY = 1
    local currDirOffset = 0
    local realFilesInDir = fs.list(currSelection)
    local filesInDir = {".."}
    local firstDraw = true
    for i=1,#realFilesInDir,1 do
        table.insert(filesInDir, #filesInDir + 1, realFilesInDir[i])
    end
    if fs.isDir(dir) then
        local stillInExplorer = true
        local redrawNext = false
        local dothide = false
        local reverseSort = false
        local e, k
        while stillInExplorer do
            local realFilesInDir = fs.list(currSelection)
            local filesInDir = {}
            if not (shell.resolve(currSelection) == "") then
                filesInDir = {".."}
            end
            for i=1,#realFilesInDir,1 do
                if dothide then
                    if not (realFilesInDir[i]:sub(1, 1) == ".") then
                        table.insert(filesInDir, #filesInDir + 1, realFilesInDir[i])
                    end
                else
                    table.insert(filesInDir, #filesInDir + 1, realFilesInDir[i])
                end
            end
            if sortType == "name" then
                table.sort(filesInDir, 
                    function (k1, k2)
                        if reverseSort then
                            if fs.isDir(currSelection .. "/" .. k1) and not fs.isDir(currSelection .. "/" .. k2) then
                                return false
                            elseif fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return k1 > k2
                            elseif not fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return true
                            else
                                return k1 > k2
                            end
                        else
                            if fs.isDir(currSelection .. "/" .. k1) and not fs.isDir(currSelection .. "/" .. k2) then
                                return true
                            elseif fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return k1 < k2
                            elseif not fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return false
                            else
                                return k1 < k2
                            end
                        end
                    end)
            elseif sortType == "extension" then
                table.sort(filesInDir, 
                    function (k1, k2)
                        if reverseSort then
                            if fs.isDir(currSelection .. "/" .. k1) and not fs.isDir(currSelection .. "/" .. k2) then
                                return false
                            elseif fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return k1 > k2
                            elseif not fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return true
                            else
                                if str.getFileExtension(k1) == str.getFileExtension(k2) then
                                    return k1 > k2
                                elseif str.getFileExtension(k1) == "" and str.getFileExtension(k2) ~= "" then
                                    return true
                                elseif str.getFileExtension(k1) ~= "" and str.getFileExtension(k2) == "" then
                                    return false
                                else
                                    return str.getFileExtension(k1) > str.getFileExtension(k2)
                                end
                            end
                        else
                            if fs.isDir(currSelection .. "/" .. k1) and not fs.isDir(currSelection .. "/" .. k2) then
                                return true
                            elseif fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return k1 < k2
                            elseif not fs.isDir(currSelection .. "/" .. k1) and fs.isDir(currSelection .. "/" .. k2) then
                                return false
                            else
                                if str.getFileExtension(k1) == str.getFileExtension(k2) then
                                    return k1 < k2
                                elseif str.getFileExtension(k1) == "" and str.getFileExtension(k2) ~= "" then
                                    return false
                                elseif str.getFileExtension(k1) ~= "" and str.getFileExtension(k2) == "" then
                                    return true
                                else
                                    return str.getFileExtension(k1) < str.getFileExtension(k2)
                                end
                            end
                        end
                    end)  --this whole large table.sort function sorts out the directories first and the extensionless files last
            elseif sortType == "size" then
                table.sort(filesInDir,
                    function (k1, k2)
                        if reverseSort then
                            return fs.getSize(currSelection.."/"..k1) > fs.getSize(currSelection.."/"..k2)
                        else
                            return fs.getSize(currSelection.."/"..k1) < fs.getSize(currSelection.."/"..k2)
                        end
                    end)
            end
            if redrawNext then
                drawDirInfo(currSelection, sortType, currDirY, currDirOffset, filesInDir, true)
                redrawNext = false
            elseif e ~= "key_up" then
                drawDirInfo(currSelection, sortType, currDirY, currDirOffset, filesInDir, firstDraw)
            end
            e, k = os.pullEvent()
            if e == "char" then
                if k == "s" then
                    if sortType == "name" then
                        sortType = "size"
                    elseif sortType == "size" then
                        sortType = "extension"
                    elseif sortType == "extension" then
                        sortType = "name"
                    end
                    redrawNext = true
                elseif k == "d" then
                    sendMsg("Please give directory name: ")
                    local newdirname = read()
                    if newdirname then
                        if fs.isReadOnly(currSelection) then
                            err("Directory is read-only")
                        else
                            fs.makeDir(currSelection.."/"..newdirname)
                        end
                    end
                    redrawNext = true
                elseif k == "D" then
                    clearScreenLine(hig)
                    local sst = "Confirm deletion of directory<"..shell.resolve(currSelection.."/"..filesInDir[currDirY + currDirOffset]).."> [{y(es)},n(o),a(ll),q(uit)]"
                    if #sst > wid then
                        clearScreenLine(hig - 1)
                        setpos(1, hig-1)
                    else
                        setpos(1, hig)
                    end
                    write(string.sub(sst, 1, wid))
                    if #sst > wid then
                        setpos(1, hig)
                        write(string.sub(sst, wid, #sst))
                    end
                    local _,op
                    while op ~= "y" and op ~= "n" and op ~= "a" and op ~= "q" do
                        _,op = pullChar()
                        if op == "y" then
                            fs.delete(currSelection.."/"..filesInDir[currDirY + currDirOffset])
                        elseif op == "a" then
                            fs.delete(currSelection)
                            fs.makeDir(currSelection)
                            currDirY = 1
                            currDirOffset = 0
                        elseif op == "q" then
                            running = false
                        end
                    end
                    clearScreenLine(hig)
                    redrawNext = true
                elseif k == "R" then
                    sendMsg("Moving "..shell.resolve(currSelection.."/"..filesInDir[currDirY + currDirOffset]).." to : "..shell.resolve(currSelection).."/")
                    fs.move(shell.resolve(currSelection.."/"..filesInDir[currDirY + currDirOffset]), shell.resolve(currSelection).."/"..read())
                elseif k == "%" then
                    sendMsg("Enter filename: ")
                    local filenamevar = read()
                    if filenamevar then
                        if fs.isDir("/"..shell.resolve(currSelection .. "/" .. filenamevar)) then
                            sendMsg("\"/"..shell.resolve(currSelection .. "/" .. filenamevar).. "\" is a directory")
                            currSelection = currSelection .. "/" .. filenamevar
                            drawDirInfo(currSelection, sortType, currDirY, currDirOffset, filesInDir, true)
                        else
                            return "/"..shell.resolve(currSelection .. "/" .. filenamevar)
                        end
                    end
                elseif k == "-" then
                    currSelection = currSelection .. "/" .. ".."
                    redrawNext = true
                elseif k == "j" then
                    if currDirY + currDirOffset < #filesInDir then
                        currDirY = currDirY + 1
                    end
                    while currDirY > hig - 7 do
                        currDirY = currDirY - 1
                        currDirOffset = currDirOffset + 1
                    end
                elseif k == "k" then
                    if currDirY + currDirOffset > 1 then
                        currDirY = currDirY - 1
                    end
                    while currDirY < 1 do
                        currDirY = currDirY + 1
                        currDirOffset = currDirOffset - 1
                    end
                elseif k == "c" then
                    shell.setDir(currSelection)
                elseif k == "g" then
                    e, k = os.pullEvent("char")
                    if e == "char" then
                        if k == "h" then
                            dothide = not dothide
                            redrawNext = true
                        end
                    end
                elseif k == "r" then
                    reverseSort = not reverseSort
                    redrawNext = true
                end
            elseif e == "key" then
                if k == keys.enter then
                    if fs.isDir(currSelection .. "/" .. filesInDir[currDirY + currDirOffset]) then
                        currSelection = currSelection .. "/" .. filesInDir[currDirY + currDirOffset]
                        currDirY = 1
                        currDirOffset = 0
                        --refresh file list
                        realFilesInDir = fs.list(currSelection)
                        if not (shell.resolve(currSelection) == "") then
                            filesInDir = {".."}
                        else
                            filesInDir = {}
                        end
                        for i=1,#realFilesInDir,1 do
                            table.insert(filesInDir, #filesInDir + 1, realFilesInDir[i])
                        end
                        redrawNext = true
                    else
                        return "/"..shell.resolve(currSelection .. "/" .. filesInDir[currDirY + currDirOffset])
                    end
                    redrawNext = true
                elseif k == keys.down then
                    if currDirY + currDirOffset < #filesInDir then
                        currDirY = currDirY + 1
                    end
                    while currDirY > hig - 7 do
                        currDirY = currDirY - 1
                        currDirOffset = currDirOffset + 1
                    end
                elseif k == keys.up then
                    if currDirY + currDirOffset > 1 then
                        currDirY = currDirY - 1
                    end
                    while currDirY < 1 do
                        currDirY = currDirY + 1
                        currDirOffset = currDirOffset - 1
                    end
                end
            elseif e == "term_resize" then
                resetSize()
                while currDirY > hig - 7 do
                    currDirY = currDirY - 1
                    currDirOffset = currDirOffset + 1
                end
                while currDirY < 1 do
                    currDirY = currDirY + 1
                    currDirOffset = currDirOffset - 1
                end
                drawDirInfo(currSelection, sortType, currDirY, currDirOffset, filesInDir, true)
            end
            if firstDraw then
                firstDraw = false
            end
        end
    else
        error("dirOpener got invalid path: "..dir.." is not a directory.")
    end
end

local lastSearch
local searchPrefix = "/"
--search the current file for a string
local function search(direction, research, currword, wrapSearchPos)
    local localcase = ignorecase
    local oldModeMsg = modeMsg
    local prevMode = currentMode
    currentMode = "c"
    clearScreenLine(hig)
    setcolors(colors.black, colors.white)
    setpos(1, hig)
    if not wrapSearchPos then
        if direction == "forward" then
            searchPrefix = "/"
        else
            searchPrefix = "?"
        end
        write(searchPrefix)
    end
    local currSearch = ""
    local searching = true
    local currline
    if research then
        currSearch = lastSearch
        currline = lastSearchLine
    elseif currword then
        currSearch = currword
        currline = currCursorY + currFileOffset
    else
        --get input
        local currHistoryItem = #sessionSearches + 1
        table.insert(sessionSearches, #sessionSearches + 1, "")
        while searching do
            modeMsg = searchPrefix .. currSearch
            local key = pullTypeaheadWRMP()
            if isCharacterKey(key) then
                local k = getSelfInsert(key)
                currSearch = currSearch .. k
                currHistoryItem = #sessionSearches
                sessionSearches[#sessionSearches] = currSearch
                --move cursor right one and write the next character
                setpos(#currSearch + #k, hig)
                write(k)
            else
                if key == "cr" then
                    searching = false
                elseif key == "bs" then
                    --delete the last character
                    currSearch = string.sub(currSearch, 1, #currSearch - 1)
                    currHistoryItem = #sessionSearches
                    sessionSearches[#sessionSearches] = currSearch
                    --move cursor left one and clear the last character
                    setpos(#currSearch + 2, hig)
                    write(" ")
                elseif key == "up" then
                    if currHistoryItem > 1 then
                        currHistoryItem = currHistoryItem - 1
                        currSearch = sessionSearches[currHistoryItem]
                        setpos(2, hig)
                        write(string.rep(" ", wid - 1))
                        setpos(2, hig)
                        write(currSearch)
                    end
                elseif key == "down" then
                    if currHistoryItem < #sessionSearches then
                        currHistoryItem = currHistoryItem + 1
                        currSearch = sessionSearches[currHistoryItem]
                        setpos(2, hig)
                        write(string.rep(" ", wid - 1))
                        setpos(2, hig)
                        write(currSearch)
                    end
                elseif key == "C-S-v" then
                    expandPaste()
                end
            end
        end
        currline = currCursorY + currFileOffset
    end
    if currSearch ~= "" then
        lastSearch = currSearch
        lastSearchLine = currline
        if not sessionSearches[#sessionSearches] == currSearch then
            table.insert(sessionSearches, #sessionSearches + 1, currSearch)
        end
    end
    if currSearch == nil then
        currSearch = ""
        currline = currCursorY + currFileOffset
    end
    --check if the last 2 characters are \c or \C, adjust the ignorecase variable
    if string.sub(currSearch, #currSearch - 1, #currSearch) == "\\c" then
        localcase = true
        --drop the last 2 characters
        currSearch = string.sub(currSearch, 1, #currSearch - 2)
    elseif string.sub(currSearch, #currSearch - 1, #currSearch) == "\\C" then
        localcase = false
        currSearch = string.sub(currSearch, 1, #currSearch - 2)
    end
    --run through the filelines and find the first line that contains the search string
    local found = false
    local foundLine = nil
    local lowerfunc
    local foundpos
    local currOffset = 0
    if localcase then
        lowerfunc = string.lower
    else
        lowerfunc = function(s) return s end
    end
    local lsp = lastSearchPos or currCursorX + currXOffset
    if wrapSearchPos then
        currline = wrapSearchPos
        lsp = nil
    else
        currline = currCursorY + currFileOffset
    end
    local lastSearchPos = lsp --this way it can be reset only for this search
    --check if there's another instance on the same line forwards or backwards from the word at lastSearchPos
    if lastSearchPos then
        if direction == "forward" then
            local searchCurrLine = lowerfunc(string.sub(filelines[currline], lastSearchPos + 1, #filelines[currline]))
            if string.find(lowerfunc(searchCurrLine), lowerfunc(currSearch)) then
                found = true
                foundLine = currline
                foundpos = string.find(searchCurrLine, lowerfunc(currSearch))
                currOffset = lastSearchPos
            end
        else
            local searchCurrLine = lowerfunc(string.sub(filelines[currline], 1, lastSearchPos - 1))
            local foundat = #searchCurrLine
            for i=foundat, 1, -1 do
                if lowerfunc(searchCurrLine:sub(i, i + #currSearch - 1)) == lowerfunc(currSearch) then
                    found = true
                    foundLine = currline
                    foundpos = i
                    break
                end
            end
        end
    end
    if not found then
        if direction == "forward" then
            for i=currline + 1,#filelines,1 do
                if string.find(lowerfunc(filelines[i]), lowerfunc(currSearch)) then
                    found = true
                    foundLine = i
                    foundpos = string.find(lowerfunc(filelines[i]), lowerfunc(currSearch))
                    break
                end
            end
        else
            for i=currline - 1,1,-1 do
                local foundat = #filelines[i]
                for j=foundat, 1, -1 do
                    if lowerfunc(filelines[i]:sub(j, j + #currSearch - 1)) == lowerfunc(currSearch) then
                        found = true
                        foundLine = i
                        foundpos = j
                        break
                    end
                end
                if found then
                    break
                end
            end
        end
    end
    if found then
        --if the search string is found, move the cursor to the line and scroll to the line
        currCursorY = foundLine
        currFileOffset = 0
        while currCursorY > hig - 1 do
            currCursorY = currCursorY - 1
            currFileOffset = currFileOffset + 1
        end
        if currCursorY < 1 then
            currCursorY = 1
        end
        --set cursor pos to start of the query string
        currCursorX = foundpos + currOffset
        lastSearchPos = currCursorX
        currXOffset = 0
        while currCursorX + lineoffset > wid do
            currCursorX = currCursorX - 1
            currXOffset = currXOffset + 1
        end
        if currCursorX < 1 then
            currCursorX = 1
        end
        redrawTerm()
    else
        if not wrapSearchPos and research then
            if direction == "forward" then
                search(direction, true, currSearch, 1)
                sendMsg("search hit BOTTOM, continuing at TOP")
            else
                search(direction, true, currSearch, #filelines)
                sendMsg("search hit TOP, continuing at BOTTOM")
            end
        else
            err("Pattern not found: "..currSearch)
        end
    end
    modeMsg = oldModeMsg
    currentMode = prevMode
end


for i=1,#decargs,1 do
    if decargs[i] == "--version" then
        print("CCVIM - ComputerCraft Vi IMproved "..version.." ("..releasedate..")")
        do return end --termination
    end
end

if #decargs["files"] > 0 then
    openfiles = decargs["files"]
    for i=1,#openfiles,1 do
        if fs.isDir(fil.topath(decargs["files"][i])) then
            decargs["files"][i] = dirOpener(fil.topath(decargs["files"][i]), decargs["files"][i])
        end
        local nodirectories = fs.getName(decargs["files"][i])
        local filenamestring = ""
        if fs.exists(fil.topath(decargs["files"][i])) then
            local doneGettingEnd = false
            for j=#nodirectories,1,-1 do
                if string.sub(nodirectories, j, j) ~= "." and not doneGettingEnd then
                    filenamestring = string.sub(nodirectories, j, j) .. filenamestring
                else
                    doneGettingEnd = true
                end
            end
            filelines = fil.toArr(fil.topath(decargs["files"][i]))
            fileContents[i] = fil.toArr(fil.topath(decargs["files"][i]))
            if not fileContents[i] then
                error(decargs["files"][i].." failed to load. If this issue persists, please create an issue on the github repository.")
            end
            if filenamestring ~= decargs["files"][i] and filenamestring ~= string.sub(decargs["files"][i], 2, #decargs["files"][i]) then
                fileContents[i]["filetype"] = filenamestring
                if fs.exists("/vim/syntax/"..filenamestring..".lua") then
                    filetypearr[filenamestring] = require("/vim/syntax/"..filenamestring)
                else
                    fileContents[i]["filetype"] = nil
                end
            else
                fileContents[i]["filetype"] = nil
            end
        else
            table.insert(openfiles, #openfiles + 1, decargs["files"][1])
            table.insert(fileContents, #fileContents + 1, {""})
            newfile = true
            local doneGettingEnd = false
            for j=#decargs["files"][i],1,-1 do
                if string.sub(decargs["files"][i], j, j) ~= "." and not doneGettingEnd then
                    filenamestring = string.sub(decargs["files"][i], j, j) .. filenamestring
                else
                    doneGettingEnd = true
                end
            end
            if filenamestring ~= decargs["files"][i] and filenamestring ~= string.sub(decargs["files"][i], 2, #decargs["files"][i]) then
                fileContents[i]["filetype"] = filenamestring
                if fs.exists("/vim/syntax/"..filenamestring..".lua") then
                    filetypearr[filenamestring] = require("/vim/syntax/"..filenamestring)
                else
                    fileContents[i]["filetype"] = nil
                end
            else
                fileContents[i]["filetype"] = nil
            end
        end
        local multilinesInFile = {{}, {}, {}} --beginning quote points, regular quote points, end quote points
        local synt
        if filenamestring ~= decargs["files"][i] and filenamestring ~= string.sub(decargs["files"][i], 2, #decargs["files"][i]) then
            if fs.exists("/vim/syntax/"..filenamestring..".lua") then
                local tmp = require("/vim/syntax/"..filenamestring)
                synt = tmp.syntax()
            end
        end
        if synt then
            local quotepoints = {}
            local justset = false
            for j=1,#fileContents[i],1 do
                local quotationmarks = str.indicesOfLetter(fileContents[i][j], synt[3])
                local inquotes = false
                justset = false
                for k=1,#fileContents[i][j],1 do
                    if tab.find(quotationmarks, k) then
                        if not inquotes then
                            if k < quotationmarks[#quotationmarks] then
                                inquotes = true
                                justset = true
                            end
                        end
                    end
                    if inquotes then
                        table.insert(quotepoints, #quotepoints, k - 2)
                    end
                    if tab.find(quotationmarks, k) and not justset then
                        if inquotes then
                            inquotes = false
                        end
                    end
                    justset = false
                end
            end
            local inmulti = false
            justset = false
            for j=1,#fileContents[i],1 do
                if str.find(fileContents[i][j], synt[7][1], quotepoints) and not inmulti then
                    inmulti = true
                    justset = true
                    table.insert(multilinesInFile[1], #multilinesInFile[1] + 1, j)
                end
                if inmulti and not (str.find(fileContents[i][j], synt[7][2])) and not justset then
                    table.insert(multilinesInFile[2], #multilinesInFile[2] + 1, j)
                end
                if str.find(fileContents[i][j], synt[7][2]) then
                    if inmulti then
                        inmulti = false
                        table.insert(multilinesInFile[3], #multilinesInFile[3] + 1, j)
                    end
                end
                justset = false
            end
            fileContents[i]["Multi-line comments"] = multilinesInFile
        end
    end
    filelines = fileContents[1]
    filename = decargs["files"][1]
    if filelines[1] ~= nil then
        local tb = str.wordBeginnings(filelines[1])
        if tb[1] then
            currCursorX = tb[1]
        else
            currCursorX = 1
        end
        while currCursorX + lineoffset > wid do
            currCursorX = currCursorX - 1
            currXOffset = currXOffset + 1
        end
        lastSearchPos = nil
        lastSearchLine = nil
    end
else
    openfiles = {}
    filelines = {""}
    currfile = 0
end

if not (#openfiles > 0) then
    setcolors(colors.black, colors.white)
    clear()
    resetSize()
    setcolors(colors.black, colors.purple)
    for i=2,hig - 1,1 do
        setpos(1,i)
        write("~")
    end
    --MOTD
    motd = true
    setcolors(colors.black, colors.white)
    setpos((wid / 2) - (33 / 2), (hig / 2) - 3)
    write("CCVIM - ComputerCraft Vi Improved")
    setpos((wid / 2) - (#("version ".. version) / 2), (hig / 2) - 1)
    write("version "..version)
    setpos((wid / 2) - (13 / 2), (hig / 2))
    write("By Minater247")
    if wid > 53 then
        setpos((wid / 2) - (46 / 2), (hig / 2) + 1)
        write("CCVIM is open source and freely distributable.")
        setpos((wid / 2) - (28 / 2), (hig / 2) + 4)
    else
        setpos((wid / 2) - (28 / 2), (hig / 2) + 3)
    end
    write("Type :q")
    setcolors(colors.black, colors.lightBlue)
    write("<Enter>       ")
    setcolors(colors.black, colors.white)
    write("to exit")

    setpos(1, 1)
    setcolors(colors.lightGray, colors.white)
    write(" ")
else
    drawFile(true)
    if newfile then
        sendMsg("\""..filename.."\" [New File]")
    else
        sendMsg("\""..filename.."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
    end
end

registerAction(":", function()
            clearScreenLine(hig)
            local cmd = pullCommand(":", false)
            local cmdtab = str.split(cmd, " ")
            lastSearchPos = nil
            lastSearchLine = nil
            if cmdtab[1] == ":sav" or cmdtab[1] == ":saveas" or cmdtab[1] == ":sav!" or cmdtab[1] == ":saveas!" then
                local name = ""
                for i=2,#cmdtab,1 do
                    name = name .. cmdtab[i]
                    if i ~= #cmdtab then
                        name = name .. " "
                    end
                end
                if #cmdtab < 2 then
                    err("Argument required")
                elseif fs.exists(fil.topath(name)) and not (cmdtab[1] == ":sav!" or cmdtab[1] == ":saveas!") then
                    err("File exists (add ! to override)")
                elseif fs.isReadOnly(fil.topath(name)) then
                    err("File is read-only")
                else
                    local new = true
                    if fs.exists(fil.topath(name)) then
                        new = false
                    end
                    local file = fs.open(fil.topath(name), "w")
                    for i=1,#filelines,1 do
                        file.writeLine(filelines[i])
                    end
                    file.close()
                    fileContents[currfile]["unsavedchanges"] = false
                    sendMsg("\""..name.."\" ")
                    if new then
                        write("[New]  ")
                    else
                        write(" ")
                    end
                    write(#filelines.."L written")
                end
            elseif cmdtab[1] == ":w" or cmdtab[1] == ":w!" then
                local name = ""
                if #cmdtab > 1 then
                    for i=2,#cmdtab,1 do
                        name = name .. cmdtab[i]
                        if i ~= #cmdtab then
                            name = name .. " "
                        end
                    end
                else
                    name = filename
                end
                if #cmdtab < 2 and filename == "" then
                    err("No file name")
                elseif fs.isReadOnly(fil.topath(name)) then
                    err("File is read-only")
                else
                    local new = true
                    if fs.exists(fil.topath(name)) then
                        new = false
                    end
                    local fl = fs.open(fil.topath(name), "w")
                    for i=1,#filelines,1 do
                        fl.writeLine(filelines[i])
                    end
                    fl.close()
                    fileContents[currfile]["unsavedchanges"] = false
                    sendMsg("\""..name.."\" ")
                    if new then
                        write("[New]  ")
                    else
                        write(" ")
                    end
                    write(#filelines.."L written")
                end
            elseif cmdtab[1] == ":q" or cmdtab[1] == ":q!" then
                if not fileContents[currfile] then
                    fileContents[currfile] = {""}
                end
                if fileContents[currfile]["unsavedchanges"] and cmdtab[1] ~= ":q!" then
                    err("No write since last change (add ! to override)")
                else
                    if #fileContents <= 1 then
                        setcolors(colors.black, colors.white)
                        clear()
                        setpos(1, 1)
                        running = false
                    else
                        table.remove(fileContents, currfile)
                        table.remove(openfiles, currfile)
                        if not (currfile == 1) then
                            currfile = currfile - 1
                        end
                        filelines = fileContents[currfile]
                        if fileContents[currfile] then
                            if fileContents[currfile]["cursor"] then
                                currCursorX = fileContents[currfile]["cursor"][1]
                                currXOffset = fileContents[currfile]["cursor"][2]
                                currCursorY = fileContents[currfile]["cursor"][3]
                                currFileOffset = fileContents[currfile]["cursor"][4]
                            end
                        end
                        recalcMLCs(true)
                        drawFile(true)
                        clearScreenLine(hig)
                        sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    end
                end
            elseif cmdtab[1] == ":wq" or cmdtab[1] == ":x" then
                local name = ""
                if openfiles[currfile] == "" then
                    for i=2,#cmdtab,1 do
                        name = name .. cmdtab[i]
                        if i ~= #cmdtab then
                            name = name .. " "
                        end
                    end
                else
                    name = openfiles[currfile]
                end
                if name then
                    if cmdtab[2] == nil and openfiles[currfile] == "" then
                        err("No file name")
                    elseif fs.isReadOnly(fil.topath(name)) then
                        err("File is read-only")
                    else
                        if name then
                            local file = fs.open(fil.topath(name), "w")
                            for i=1,#filelines,1 do
                                file.writeLine(filelines[i])
                            end
                            file.close()
                            fileContents[currfile]["unsavedchanges"] = false
                            if #fileContents == 1 then
                                setcolors(colors.black, colors.white)
                                clear()
                                setpos(1, 1)
                                running = false
                            else
                                table.remove(fileContents, currfile)
                                table.remove(openfiles, currfile)
                                if not (currfile == 1) then
                                    currfile = currfile - 1
                                end
                                filelines = fileContents[currfile]
                                if fileContents[currfile]["cursor"] then
                                    currCursorX = fileContents[currfile]["cursor"][1]
                                    currXOffset = fileContents[currfile]["cursor"][2]
                                    currCursorY = fileContents[currfile]["cursor"][3]
                                    currFileOffset = fileContents[currfile]["cursor"][4]
                                end
                                recalcMLCs(true)
                                drawFile(true)
                                clearScreenLine(hig)
                            end
                        end
                    end
                else
                    err("No file name")
                end
            elseif cmdtab[1] == ":e" or cmdtab[1] == ":ex" then
                if #cmdtab > 1 then
                    if not motd then
                        if currfile == 0 then
                            currfile = 1
                        end
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        if not openfiles[currfile] then
                            openfiles[currfile] = ""
                        end
                    end
                    local name = ""
                    for i=2,#cmdtab,1 do
                        name = name .. cmdtab[i]
                        if i ~= #cmdtab then
                            name = name .. " "
                        end
                    end
                    if name then
                        if fs.isDir(fil.topath(name)) then
                            filename = dirOpener(fil.topath(name))
                        else
                            filename = name
                        
                        end
                    else
                        filename = ""
                    end
                    table.insert(openfiles, #openfiles + 1, filename)
                    if currfile == 0 then
                        currfile = 1
                    end
                    newfile = false
                    if fs.exists(fil.topath(filename)) then
                        filelines = fil.toArr(fil.topath(filename))
                        if filelines then
                            sendMsg("\""..filename.."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                        else
                            newfile = true
                            sendMsg("\""..filename.."\" [New File]")
                        end
                    else
                        newfile = true
                        sendMsg("\""..filename.."\" [New File]")
                    end
                    table.insert(fileContents, #fileContents + 1, fil.toArr(fil.topath(filename)))
                    if not fileContents[#fileContents] then
                        fileContents[#fileContents] = {""}
                    end
                    currfile = #fileContents
                    filelines = fileContents[currfile]
                    currFileOffset = 0
                    if filelines[1] ~= nil then
                        local tb = str.wordBeginnings(filelines[1])
                        if tb[1] then
                            currCursorX = tb[1]
                        else
                            currCursorX = 1
                        end
                        while currCursorX + lineoffset > wid do
                            currCursorX = currCursorX - 1
                            currXOffset = currXOffset + 1
                        end
                    end
                    local doneGettingEnd = false
                    local filenamestring = string.sub(openfiles[currfile], string.find(openfiles[currfile], "%.") + 1, #openfiles[currfile])
                    if filenamestring ~= openfiles[currfile] and filenamestring ~= string.sub(openfiles[currfile], 2, #openfiles[currfile]) then
                        fileContents[currfile]["filetype"] = filenamestring
                        if fs.exists("/vim/syntax/"..filenamestring..".lua") then
                            filetypearr[filenamestring] = require("/vim/syntax/"..filenamestring)
                        else
                            fileContents[currfile]["filetype"] = nil
                        end
                    else
                        fileContents[currfile]["filetype"] = nil
                    end
                    if newfile then
                        moveCursorRight()
                    end
                    recalcMLCs(true)
                    drawFile(true)
                else
                    err("No file name")
                end
            elseif cmdtab[1] == ":r" or cmdtab[1] == ":read" then
                if #cmdtab > 1 then
                    local name = ""
                    for i=2,#cmdtab,1 do
                        name = name .. cmdtab[i]
                        if i ~= #cmdtab then
                            name = name .. " "
                        end
                    end
                    if fs.exists(fil.topath(name)) then
                        if fs.isDir(fil.topath(name)) then
                            name = dirOpener(fil.topath(name))
                        end
                        local secondArr = fil.toArr(fil.topath(name))
                        for i=1,#secondArr,1 do
                            table.insert(filelines, #filelines + 1, secondArr[i])
                        end
                        if not fileContents[currfile] then
                            fileContents[currfile] = filelines
                        end
                        recalcMLCs(true)
                        drawFile(true)
                        sendMsg("\""..name.."\" "..#secondArr.."L, "..tab.countchars(secondArr).."C")
                        motd = false
                    else
                        err("Can't open file "..name)
                    end
                else
                    err("No file name")
                end
            elseif cmdtab[1] == ":tabn" or cmdtab[1] == ":tabnext" then
                if #fileContents > 1 then
                    if currfile ~= #fileContents then
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = currfile + 1
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                    else
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = 1
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                    end
                    recalcMLCs(true)
                    drawFile(true)
                    sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    filename = openfiles[currfile]
                end
            elseif cmdtab[1] == ":tabp" or cmdtab[1] == ":tabprevious" then
                if #fileContents > 1 then
                    if currfile ~= 1 then
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = currfile - 1
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                    else
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = #fileContents
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                    end
                    recalcMLCs(true)
                    drawFile(true)
                    sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    filename = openfiles[currfile]
                end
            elseif cmdtab[1] == ":tabm" or cmdtab[1] == ":tabmove" then
                fileContents[currfile] = filelines
                fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                local tmp = tonumber(cmdtab[2])
                if tonumber(cmdtab[2]) >= 0 and tonumber(cmdtab[2]) <= #fileContents - 1 then
                    currfile = tonumber(cmdtab[2]) + 1
                    filelines = fileContents[currfile]
                    if fileContents[currfile]["cursor"] then
                        currCursorX = fileContents[currfile]["cursor"][1]
                        currXOffset = fileContents[currfile]["cursor"][2]
                        currCursorY = fileContents[currfile]["cursor"][3]
                        currFileOffset = fileContents[currfile]["cursor"][4]
                    end
                    recalcMLCs(true)
                    drawFile(true)
                    sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                end
                clearScreenLine(hig)
            elseif cmdtab[1] == ":tabo" or cmdtab[1] == ":tabonly" or cmdtab[1] == ":tabo!" or cmdtab[1] == ":tabonly!" then
                local closable = true
                local unclosablename = ""
                local unclosablenum = -1
                for i=1,#fileContents,1 do
                    if fileContents[i]["unsavedchanges"] and not (i == currfile) and cmdtab[1] ~= ":tabo!" and cmdtab[1] ~= ":tabonly!" then
                        closable = false
                        unclosablename = openfiles[i]
                        unclosablenum = i
                    end
                end
                if not closable then
                    err("Unsaved work in \""..unclosablename.."\" (add ! to override)")
                else
                    fileContents = {fileContents[currfile]}
                    openfiles = {openfiles[currfile]}
                    currfile = 1
                    filelines = fileContents[currfile]
                    if fileContents[currfile]["cursor"] then
                        currCursorX = fileContents[currfile]["cursor"][1]
                        currXOffset = fileContents[currfile]["cursor"][2]
                        currCursorY = fileContents[currfile]["cursor"][3]
                        currFileOffset = fileContents[currfile]["cursor"][4]
                    end
                    drawFile()
                    clearScreenLine(hig)
                    sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                end
            elseif cmdtab[1] == ":tabnew" then
                if not cmdtab[2] then
                    cmdtab[2] = 1
                end
                if tonumber(cmdtab[2]) ~= nil then
                    for i=1,tonumber(cmdtab[2]),1 do
                        table.insert(fileContents, currfile + 1, {""})
                        table.insert(openfiles, currfile + 1, "")
                    end
                    sendMsg("added "..tonumber(cmdtab[2]).." new tab")
                    if tonumber(cmdtab[2]) > 1 then
                        write("s")
                    end
                    fileContents[currfile] = filelines
                    fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                    currfile = currfile + 1
                    filelines = fileContents[currfile]
                    if openfiles[currfile] ~= "" then
                        sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    else
                        sendMsg("\""..openfiles[currfile].."\"  [New File] "..#filelines.."L, "..tab.countchars(filelines).."C")
                    end
                    currCursorX = 1
                    currXOffset = 0
                    currCursorY = 1
                    currFileOffset = 0
                    recalcMLCs(true)
                    drawFile(true)
                else
                    if cmdtab[2] then
                        local name = ""
                        for i=2,#cmdtab,1 do
                            name = name .. cmdtab[i]
                            if i ~= #cmdtab then
                                name = name .. " "
                            end
                        end
                        if fs.exists(fil.topath(name)) then
                            if fs.isDir(fil.topath(name)) then
                                name = dirOpener(fil.topath(name))
                            else
                                name = fil.topath(name)
                            end
                            fileContents[currfile] = filelines
                            fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                            table.insert(fileContents, currfile + 1, fil.toArr(fil.topath(name)))
                            local newfile = false
                            if not fileContents[#fileContents] then
                                newfile = true
                                fileContents[#fileContents] = {""}
                            end
                            table.insert(openfiles, currfile + 1, name)
                            currfile = currfile + 1
                            filelines = fileContents[currfile]
                            openfiles[currfile] = name
                            filename = openfiles[currfile]
                            if newfile then
                                sendMsg("\""..openfiles[currfile].."\"  [New File] "..#filelines.."L, "..tab.countchars(filelines).."C")
                            else
                                sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                            end
                            currCursorX = 1
                            currXOffset = 0
                            currCursorY = 1
                            currFileOffset = 0
                            local tb = str.wordBeginnings(filelines[1])
                            if tb[1] then
                                currCursorX = tb[1]
                            else
                                currCursorX = 1
                            end
                            while currCursorX + lineoffset > wid do
                                currCursorX = currCursorX - 1
                                currXOffset = currXOffset + 1
                            end
                            if string.find(openfiles[currfile], "%.") then
                                local filenamestring = string.sub(openfiles[currfile], string.find(openfiles[currfile], "%.") + 1, #openfiles[currfile])
                                if fs.exists("/vim/syntax/"..filenamestring..".lua") then
                                    filetypearr[filenamestring] = require("/vim/syntax/"..filenamestring)
                                else
                                    fileContents[currfile]["filetype"] = nil
                                end
                                fileContents[currfile]["filetype"] = filenamestring
                            end
                            recalcMLCs(true)
                            drawFile(true)
                        else
                            name = fil.topath(name)
                            local templines = fil.toArr(name)
                            if templines then
                                table.insert(fileContents, currfile + 1, templines)
                            else
                                table.insert(fileContents, currfile + 1, {""})
                            end
                            table.insert(openfiles, currfile + 1, name)
                            fileContents[currfile] = filelines
                            fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                            currfile = currfile + 1
                            filelines = fileContents[currfile]
                            openfiles[currfile] = name
                            sendMsg("\""..openfiles[currfile].."\"  [New File] "..#filelines.."L, "..tab.countchars(filelines).."C")
                            currCursorX = 1
                            currXOffset = 0
                            currCursorY = 1
                            currFileOffset = 0
                            if string.find(openfiles[currfile], "%.") then
                                local filenamestring = string.sub(openfiles[currfile], string.find(openfiles[currfile], "%.") + 1, #openfiles[currfile])
                                if fs.exists("/vim/syntax/"..filenamestring..".lua") then
                                    filetypearr[filenamestring] = require("/vim/syntax/"..filenamestring)
                                else
                                    fileContents[currfile]["filetype"] = nil
                                end
                                fileContents[currfile]["filetype"] = filenamestring
                            end
                            recalcMLCs(true)
                            drawFile(true)
                        end
                    else
                        --just add an empty tab
                        table.insert(fileContents, currfile + 1, {""})
                        table.insert(openfiles, currfile + 1, "")
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = currfile + 1
                        filelines = fileContents[currfile]
                        sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                        currCursorX = 1
                        currXOffset = 0
                        currCursorY = 1
                        currFileOffset = 0
                        recalcMLCs(true)
                        drawFile(true)
                    end
                end
                if string.find(openfiles[currfile], "%.") then
                    fileContents[currfile]["filetype"] = string.sub(openfiles[currfile], string.find(openfiles[currfile], "%.") + 1, #openfiles[currfile])
                end
            elseif cmdtab[1] == ":tabc" or cmdtab[1] == ":tabclose" or cmdtab[1] == ":tabc!" or cmdtab[1] == ":tabclose!" then
                if fileContents[currfile]["unsavedchanges"] and cmdtab[1] ~= ":tabc!" and cmdtab[1] ~= ":tabclose!" then
                    err("No write since last change (add ! to override)")
                else
                    if #fileContents == 1 then
                        setcolors(colors.black, colors.white)
                        clear()
                        setpos(1, 1)
                        running = false
                    else
                        table.remove(fileContents, currfile)
                        table.remove(openfiles, currfile)
                        if not (currfile == 1) then
                            currfile = currfile - 1
                        end
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                        recalcMLCs(true)
                        drawFile(true)
                        clearScreenLine(hig)
                        sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    end
                end
            elseif cmdtab[1] == ":set" then
                local seterror = false
                if cmdtab[2] == "number" then
                    linenumbers = true
                    lineoffset= 4
                    drawFile(true)
                elseif cmdtab[2] == "mobile" then
                    mobile = true
                elseif cmdtab[2] == "nonumber" then
                    linenumbers = false
                    lineoffset = 0
                    drawFile(true)
                elseif cmdtab[2] == "nomobile" then
                    mobile = false
                elseif cmdtab[2] == "lowspec" then
                    lowspec = true
                    drawFile(true)
                elseif cmdtab[2] == "nolowspec" then
                    lowspec = false
                    drawFile(true)
                elseif cmdtab[2] == "scroll?" then
                    -- FIXME message seems to be immediately disappear
                    sendMsg("  scroll=" .. scrollOption)
                elseif str.find(cmdtab[2], "=") then
                    local tmp = str.split(cmdtab[2], "=")
                    local comm = tmp[1]
                    local stri = ""
                    for i=2,#tmp,1 do
                        stri = stri .. tmp[i]
                        if i ~= #tmp then
                            stri = stri .. "="
                        end
                    end
                    if comm == "filetype" then
                        if stri ~= openfiles[currfile] and stri ~= string.sub(openfiles[currfile], 2, #openfiles[currfile]) then
                            fileContents[currfile]["filetype"] = stri
                            if fs.exists("/vim/syntax/"..stri..".lua") then
                                filetypearr[stri] = require("/vim/syntax/"..stri)
                            else
                                fileContents[currfile]["filetype"] = nil
                            end
                        else
                            fileContents[currfile]["filetype"] = nil
                        end
                    elseif comm == "scale" then
                        if monitor and tonumber(stri) then
                            monitor.setTextScale(tonumber(stri))
                        end
                    elseif comm == "scroll" then
                        if tonumber(stri) then
                            scrollOption = tonumber(stri)
                        end
                    end
                    resetSize()
                    recalcMLCs(true)
                    redrawTerm()
                    drawFile(true)
                elseif cmdtab[2] == "autoindent" then
                    autoindent = true
                elseif cmdtab[2] == "noautoindent" then
                    autoindent = false
                elseif cmdtab[2] == "ignorecase" or cmdtab[2] == "ic" then
                    ignorecase = true
                elseif cmdtab[2] == "noignorecase" or cmdtab[2] == "noic" then
                    ignorecase = false
                else
                    err("Variable " .. cmdtab[2] .. " not supported.")
                    seterror = true
                end
                if not seterror then
                    clearScreenLine(hig)
                end
            elseif cmdtab[1] == ":resetscale" then
                resetSize()
                redrawTerm()
            elseif cmdtab[1] == ":syntax" then
                if cmdtab[2] == "on" then
                    syntaxhighlighting = true
                elseif cmdtab[2] == "off" then
                    syntaxhighlighting = false
                else
                    err("invalid :syntax subcommand: "..cmdtab[2])
                end
                recalcMLCs(true)
                drawFile(true)
            elseif cmdtab[1] == ":control" or cmdtab[1] == ":ctrl" then --not yet working
                local _, ch
                if not cmdtab[2] then
                    sendMsg("Emulating held control until next key press:")
                    _, ch = os.pullEvent("char")  -- TODO pull one key from the typeahead, modify it with ctrl and prepend it again
                    sendMsg("Sent CONTROL + "..ch)
                else
                    ch = cmdtab[2]
                    clearScreenLine(hig)
                end
                if ch == "e" then
                    currFileOffset = currFileOffset + 1
                    currCursorY = currCursorY - 1
                elseif ch == "y" then
                    currFileOffset = currFileOffset - 1
                    currCursorY = currCursorY + 1
                elseif ch == "b" then
                    local oldCursorY = currCursorY
                    if currCursorY + currFileOffset > hig - 1 then
                        currCursorY = currCursorY - (hig - 1)
                    end
                    while currCursorY < oldCursorY do
                        currCursorY = currCursorY + 1
                        currFileOffset = currFileOffset - 1
                    end
                elseif ch == "f" then
                    local oldCursorY = currCursorY
                    if currCursorY + currFileOffset < #filelines - (hig - 1) then
                        currCursorY = currCursorY + (hig - 1)
                    end
                    while currCursorY > oldCursorY do
                        currCursorY = currCursorY - 1
                        currFileOffset = currFileOffset + 1
                    end
                elseif ch == "d" then
                    local oldCursorY = currCursorY
                    if currCursorY + currFileOffset < #filelines - math.floor((hig - 1)/2) then
                        currCursorY = currCursorY + math.floor((hig - 1)/2)
                    end
                    while currCursorY > oldCursorY do
                        currCursorY = currCursorY - 1
                        currFileOffset = currFileOffset + 1
                    end
                    while currFileOffset > #filelines - (hig - 1) do
                        currFileOffset = currFileOffset - 1
                        currCursorY = currCursorY + 1
                    end
                elseif ch == "u" then
                    local oldCursorY = currCursorY
                    if currCursorY + currFileOffset > (hig - 1) then
                        currCursorY = currCursorY - math.floor((hig - 1)/2)
                    end
                    while currCursorY < oldCursorY do
                        currCursorY = currCursorY + 1
                        currFileOffset = currFileOffset - 1
                    end
                    while currFileOffset < 0 do
                        currFileOffset = currFileOffset + 1
                        currCursorY = currCursorY - 1
                    end
                end
                drawFile()
            elseif cmdtab[1] == ":dbgex" then --debug 
                local ff = fs.open("/vim/debug.exp", "w")
                ff.write("Line offset: "..lineoffset.."\n")
                ff.write("Cursor Y: "..currCursorY.."\n")
                ff.write("Cursor X: "..currCursorX.."\n")
                ff.write("File offset: "..currFileOffset.."\n")
                ff.write("Cursor X offset: "..currXOffset.."\n")
                ff.write("Last search: "..lastSearch.."\n")
                ff.write("Last search line gotten: "..lastSearchLine.."\n")
                for i=1,#filelines,1 do
                    ff.write(filelines[i].."\n")
                end
                ff.close()
            elseif cmdtab[1] ~= "" then
                err("Not an editor command or unimplemented: "..cmdtab[1])
            end
        end)
registerAction("i", function()
            insertMode()
        end)
registerAction("I", function()
            currXOffset = 0
            currCursorX = 1
            drawFile(true)
            insertMode()
        end)
registerAction("h", function()
    resetLastSearch()
    if repeatCount0 > 0 then
        -- TODO figure out why does the original repetition code contain this
        currCursorX = currCursorX - repeatCount0 + 1
    else
        currCursorX = currCursorX - 1
    end
    if currCursorX + currXOffset < 1 then
        currCursorX = 1
        currXOffset = 0
    else
        while currCursorX < 1 do
            currCursorX = currCursorX + 1
            currXOffset = currXOffset - 1
        end
    end
    drawFile()
    oldx = nil
end)
registerAction("j", function()
    resetLastSearch()
    if oldx ~= nil then
        currCursorX = oldx - currXOffset
    else
        oldx = currCursorX + currXOffset
    end
    currCursorY = currCursorY + repeatCount1
    if currCursorY + currFileOffset > #filelines then
        currCursorY = #filelines
        currFileOffset = 0
    end
    if currCursorX + currXOffset > #(filelines[currCursorY + currFileOffset]) + 1 then
        if filelines[currCursorY + currFileOffset] ~= "" then
            currCursorX = #(filelines[currCursorY + currFileOffset]) + 1 - currXOffset
        else
            currCursorX = 1
            currXOffset = 0
        end
    end
    if currCursorX < 1 then
        while currCursorX < 1 do
            currXOffset = currXOffset - 1
            currCursorX = currCursorX + 1
        end
    elseif currCursorX + lineoffset > wid then
        while currCursorX + lineoffset > wid do
            currXOffset = currXOffset + 1
            currCursorX = currCursorX - 1
        end
    end
    while currCursorY > hig - 1 do
        currCursorY = currCursorY - 1
        currFileOffset = currFileOffset + 1
    end
    drawFile(repeatCount1 > 1)  -- Force redraw to avoid phantom cursor
end)
registerAction("k", function()
    resetLastSearch()
    if oldx ~= nil then
        currCursorX = oldx - currXOffset
    else
        oldx = currCursorX + currXOffset
    end
    currCursorY = currCursorY - repeatCount1
    if currCursorY + currFileOffset < 1 then
        currCursorY = 1
        currFileOffset = 0
    end
    if currCursorX + currXOffset > #(filelines[currCursorY + currFileOffset]) + 1 then
        if filelines[currCursorY + currFileOffset] ~= "" then
            currCursorX = #(filelines[currCursorY + currFileOffset]) + 1 - currXOffset
        else
            currCursorX = 1
            currXOffset = 0
        end
    end
    if currCursorX < 1 then
        while currCursorX < 1 do
            currXOffset = currXOffset - 1
            currCursorX = currCursorX + 1
        end
    elseif currCursorX + lineoffset > wid then
        while currCursorX + lineoffset > wid do
            currXOffset = currXOffset + 1
            currCursorX = currCursorX - 1
        end
    end
    while currCursorY < 1 do
        currCursorY = currCursorY + 1
        currFileOffset = currFileOffset - 1
    end
    while currFileOffset < 0 do
        currFileOffset = currFileOffset + 1
    end
    drawFile(repeatCount1 > 1)  -- Force redraw to avoid phantom cursor
end)
registerAction("l", function()
    resetLastSearch()
    currCursorX = currCursorX + repeatCount1
    local line = filelines[currCursorY + currFileOffset]
    if line ~= nil then
        if currCursorX + currXOffset > #line then
            currXOffset = 0
            currCursorX = #filelines[currCursorY + currFileOffset] + 1
        end
        if currCursorX + lineoffset > wid then
            local delta = wid - currCursorX - lineoffset
            currCursorX = currCursorX + delta
            currXOffset = currXOffset - delta
        end
        drawFile()
    end
    oldx = nil
end)
registerAction("H", function()
            currCursorY = 1
            drawFile(true)
        end)
registerAction("M", function()
            currCursorY = math.floor((hig - 1) / 2)
            drawFile(true)
        end)
registerAction("L", function()
            currCursorY = hig - 1
            drawFile(true)
        end)
registerAction("r", function()
            local chr = pullTypeaheadCharMode("i")
            filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1) .. chr .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset + 1, #(filelines[currCursorY + currFileOffset]))
            recalcMLCs()
            drawFile(true)
            if fileContents[currfile] then
                fileContents[currfile]["unsavedchanges"] = true
            end
        end)
registerAction("J", function()
            if filelines[currCursorY + currFileOffset] and filelines[currCursorY + currFileOffset + 1] then
                filelines[currCursorY + currFileOffset] = filelines[currCursorY + currFileOffset] .. " " .. filelines[currCursorY + currFileOffset + 1]
                table.remove(filelines, currCursorY + currFileOffset + 1)
                recalcMLCs()
                drawFile(true)
                fileContents[currfile]["unsavedchanges"] = true
            end
        end)
registerAction("o", function()
            lastSearchPos = nil
            lastSearchLine = nil
            table.insert(filelines, currCursorY + currFileOffset + 1, "")
            moveCursorDown()
            currCursorX = 1
            currXOffset = 0
            recalcMLCs()
            drawFile(true)
            insertMode()
            if fileContents[currfile] then
                fileContents[currfile]["unsavedchanges"] = true
            end
        end)
registerAction("O", function()
            lastSearchPos = nil
            lastSearchLine = nil
            table.insert(filelines, currCursorY + currFileOffset, "")
            currCursorX = 1
            currXOffset = 0
            recalcMLCs()
            drawFile(true)
            insertMode()
            fileContents[currfile]["unsavedchanges"] = true
        end)
registerAction("a", function()
            moveCursorRight(0)
            insertMode()
        end)
registerAction("A", function()
            lastSearchPos = nil
            lastSearchLine = nil
            currCursorX = #filelines[currCursorY + currFileOffset]
            currXOffset = 0
            while currCursorX + lineoffset > wid do
                currXOffset = currXOffset + 1
                currCursorX = currCursorX - 1
            end
            drawFile()
            moveCursorRight(0)
            insertMode()
        end)
registerAction("ZQ", function()
                setcolors(colors.black, colors.white)
                clear()
                setpos(1, 1)
                running = false
            end)
registerAction("ZZ", function()
                if filename == "" then
                    err("No file name")
                else
                    local file = fs.open(fil.topath(filename), "w")
                    for i=1,#filelines,1 do
                        file.writeLine(filelines[i])
                    end
                    file.close()
                    fileContents[currfile]["unsavedchanges"] = false
                    setcolors(colors.black, colors.white)
                    clear()
                    setpos(1, 1)
                    running = false
                end
            end)
registerAction("yy", function()
    local count = #filelines - currCursorY - currFileOffset + 1
    if count > repeatCount1 then
        count = repeatCount1
    end
    copybuffer = {}
    for i = 1, count, 1 do
        table.insert(copybuffer, #copybuffer + 1, filelines[currCursorY + currFileOffset + i - 1])
    end
    copytype = "linetable"
end)
registerAction("yw", function()
                local word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                copybuffer = word
                if ed ~= #filelines[currCursorY + currFileOffset] then
                    copybuffer = copybuffer .. " "
                end
                copytype = "text"
            end)
registerAction("yiw", function()
                    local word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                    copybuffer = word
                    copytype = "text"
                end)
registerAction("yaw", function()
                    local word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                    copybuffer = word
                    if ed ~= #filelines[currCursorY + currFileOffset] then
                        copybuffer = copybuffer .. " "
                    elseif beg ~= 1 then
                        copybuffer = " " .. copybuffer
                    end
                    copytype = "text"
                end)
registerAction("y$", function()
                copybuffer = string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #filelines[currCursorY + currFileOffset])
                copytype = "text"
            end)
registerAction("x", function()
            copybuffer = string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset)
            copytype = "text"
            filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1) .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset + 1, #filelines[currCursorY + currFileOffset])
            recalcMLCs()
            drawFile()
            if fileContents[currfile] then
                fileContents[currfile]["unsavedchanges"] = true
            end
        end)
function resetLastSearch()
            lastSearchPos = nil
            lastSearchLine = nil
        end
local afterDelete
registerAction("dd", function() resetLastSearch()
    local count = #filelines - currCursorY - currFileOffset + 1
    if count > repeatCount1 then
        count = repeatCount1
    end
    copybuffer = {}
    for i = 1, count, 1 do
        table.insert(copybuffer, #copybuffer + 1, filelines[currCursorY + currFileOffset + i - 1])
    end
    copytype = "linetable"
    for i = 1, count, 1 do
        table.remove(filelines, currCursorY + currFileOffset)
    end
    if #filelines < 1 then
        filelines[1] = ""
    end
    fileContents[currfile]["unsavedchanges"] = true
    afterDelete()
end)
registerAction("dw", function() resetLastSearch()
                local word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                copybuffer = word
                if ed ~= #filelines[currCursorY + currFileOffset] then
                    copybuffer = copybuffer .. " "
                end
                copytype = "text"
                if ed ~= #filelines[currCursorY + currFileOffset] then
                    ed = ed + 1
                end
                currCursorX = beg - 1
                filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, beg - 1) .. string.sub(filelines[currCursorY + currFileOffset], ed + 1, #filelines[currCursorY + currFileOffset])
                fileContents[currfile]["unsavedchanges"] = true
            afterDelete() end)
registerAction("diw", function() resetLastSearch() local word, beg, ed
                local word,beg,ed
                    word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                    copybuffer = word
                    copytype = "text"
                    filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, beg - 1) .. string.sub(filelines[currCursorY + currFileOffset], ed + 1, #filelines[currCursorY + currFileOffset])
                    fileContents[currfile]["unsavedchanges"] = true
                    currCursorX = beg - 1
                afterDelete() end)
registerAction("daw", function() resetLastSearch()
                    local word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                    copybuffer = word
                    if ed ~= #filelines[currCursorY + currFileOffset] then
                        copybuffer = copybuffer .. " "
                        ed = ed + 1
                    elseif beg ~= 1 then
                        copybuffer = " " .. copybuffer
                        beg = beg - 1
                    end
                    copytype = "text"
                    currCursorX = beg - 1
                    filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, beg - 1) .. string.sub(filelines[currCursorY + currFileOffset], ed + 1, #filelines[currCursorY + currFileOffset])
                    fileContents[currfile]["unsavedchanges"] = true
                afterDelete() end)
registerAction("d$", function() resetLastSearch()
                copybuffer = string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #filelines[currCursorY + currFileOffset])
                copytype = "text"
                filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1)
                fileContents[currfile]["unsavedchanges"] = true
            afterDelete() end)
function afterDelete()
            while currCursorY + currFileOffset > #filelines do
                currCursorY = currCursorY - 1
                if currCursorY < 1 then
                    while currCursorY < 1 do
                        currFileOffset = currFileOffset - 1
                        currCursorY = currCursorY + 1
                    end
                end
            end
            while currCursorX + currXOffset > #filelines[currCursorY + currFileOffset] do
                currCursorX = currCursorX - 1
                if currCursorX < 1 then
                    while currCursorX < 1 do
                        currXOffset = currXOffset - 1
                        currCursorX = currCursorX + 1
                    end
                end
            end
            recalcMLCs()
            drawFile(true)
        end
registerAction("D", function()
            lastSearchPos = nil
            lastSearchLine = nil
            copybuffer = string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #filelines[currCursorY + currFileOffset])
            copytype = "text"
            filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1)
            drawFile()
            recalcMLCs()
            fileContents[currfile]["unsavedchanges"] = true
        end)
registerAction("p", function()
            lastSearchPos = nil
            lastSearchLine = nil
            if copytype == "line" then
                table.insert(filelines, currCursorY + currFileOffset + 1, copybuffer)
            elseif copytype == "text" then
                filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset) .. copybuffer .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset + 1, #filelines[currCursorY + currFileOffset])
                currCursorX = currCursorX + #copybuffer --minus one so we can have the function reset viewpoint
                while currCursorX + lineoffset > wid do
                    currCursorX = currCursorX - 1
                    currXOffset = currXOffset + 1
                end
            elseif copytype == "linetable" then
                for i=#copybuffer,1,-1 do
                    table.insert(filelines, currCursorY + currFileOffset + 1, copybuffer[i])
                end
            end
            recalcMLCs(true)
            drawFile(true)
            if fileContents[currfile] then
                fileContents[currfile]["unsavedchanges"] = true
            end
        end)
registerAction("P", function()
            lastSearchPos = nil
            lastSearchLine = nil
            if copytype == "line" then
                table.insert(filelines, currCursorY + currFileOffset, copybuffer)
            elseif copytype == "text" then
                filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1) .. copybuffer .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, #filelines[currCursorY + currFileOffset])
                currCursorX = currCursorX + #copybuffer
                while currCursorX + lineoffset > wid do
                    currCursorX = currCursorX - 1
                    currXOffset = currXOffset + 1
                end
            elseif copytype == "linetable" then
                for i=#copybuffer,1,-1 do
                    table.insert(filelines, currCursorY + currFileOffset, copybuffer[i])
                end
                currCursorY = currCursorY + #copybuffer
                while currCursorY > hig - 1 do
                    currCursorY = currCursorY - 1
                    currFileOffset = currFileOffset + 1
                end
            end
            recalcMLCs(true)
            drawFile(true)
            fileContents[currfile]["unsavedchanges"] = true
        end)
registerAction("$", function()
            lastSearchPos = nil
            lastSearchLine = nil
            oldx = 999999999
            currCursorX = #filelines[currCursorY + currFileOffset]
            currXOffset = 0
            while currCursorX + lineoffset > wid do
                currCursorX = currCursorX - 1
                currXOffset = currXOffset + 1
            end
            drawFile()
        end)
registerAction("0", function()
            lastSearchPos = nil
            lastSearchLine = nil
            currCursorX = 1
            currXOffset = 0
            drawFile()
        end)
registerAction("gJ", function() resetLastSearch()
                filelines[currCursorY + currFileOffset] = filelines[currCursorY + currFileOffset] .. filelines[currCursorY + currFileOffset + 1]
                table.remove(filelines, currCursorY + currFileOffset + 1)
                recalcMLCs()
                drawFile(true)
                fileContents[currfile]["unsavedchanges"] = true
            end)
registerAction("gg", function() resetLastSearch()
                currCursorY = repeatCount1
                currFileOffset = 0
                currCursorX = 1
                currXOffset = 0
                while currCursorY > hig - 1 do
                    currCursorY = currCursorY - 1
                    currFileOffset = currFileOffset + 1
                end
                drawFile()
            end)
registerActionMulti({{"g"}, {"e", "E"}}, function(lst)
    local c = lst[2]
    return (function() resetLastSearch()
            for i = 1, repeatCount1, 1 do
                local begs = str.wordEnds(filelines[currCursorY + currFileOffset], not string.match(c, "%u"))
                if begs[#begs] then
                    if currCursorX + currXOffset > begs[1] then
                        currCursorX = currCursorX - 1
                        while not tab.find(begs, currCursorX + currXOffset) do
                            currCursorX = currCursorX - 1
                        end
                        while currCursorX < 1 do
                            currCursorX = currCursorX + 1
                            currXOffset = currXOffset - 1
                        end
                        oldx = currCursorX + currXOffset
                    end
                end
            end
            drawFile()
        end)
    end)
registerAction("g_", function() resetLastSearch()
                currCursorX = #filelines[currCursorY + currFileOffset]
                currXOffset = 0
                local i = currCursorX
                while string.sub(filelines[currCursorY + currFileOffset], i, i) == " " do
                    i = i - 1
                end
                currCursorX = i
                if currCursorX + lineoffset > wid then
                    while currCursorX + lineoffset > wid do
                        currCursorX = currCursorX - 1
                        currXOffset = currXOffset + 1
                    end
                elseif currCursorX < 1 then
                    while currCursorX < 1 do
                        currCursorX = currCursorX + 1
                        currXOffset = currXOffset - 1
                    end
                end
                drawFile()
            end)
registerAction("gt", function() resetLastSearch()
    fileContents[currfile] = filelines
    fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
    if repeatCount0 > 0 then
        currfile = repeatCount0
    else
        currfile = currfile + 1
    end
    if currfile > #fileContents then
        currfile = (currfile - 1) % #fileContents + 1
    end
    filelines = fileContents[currfile]
    if fileContents[currfile]["cursor"] then
        currCursorX = fileContents[currfile]["cursor"][1]
        currXOffset = fileContents[currfile]["cursor"][2]
        currCursorY = fileContents[currfile]["cursor"][3]
        currFileOffset = fileContents[currfile]["cursor"][4]
    end
    recalcMLCs(true)
    drawFile(true)
    sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
end)
registerAction("gT", function() resetLastSearch()
                if #fileContents > 1 then
                    if currfile ~= 1 then
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = currfile - 1
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                        recalcMLCs(true)
                        drawFile(true)
                        sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    else
                        fileContents[currfile] = filelines
                        fileContents[currfile]["cursor"] = {currCursorX, currXOffset, currCursorY, currFileOffset}
                        currfile = #fileContents
                        filelines = fileContents[currfile]
                        if fileContents[currfile]["cursor"] then
                            currCursorX = fileContents[currfile]["cursor"][1]
                            currXOffset = fileContents[currfile]["cursor"][2]
                            currCursorY = fileContents[currfile]["cursor"][3]
                            currFileOffset = fileContents[currfile]["cursor"][4]
                        end
                        recalcMLCs(true)
                        drawFile(true)
                        sendMsg("\""..openfiles[currfile].."\" "..#filelines.."L, "..tab.countchars(filelines).."C")
                    end
                    filename = openfiles[currfile]
                end
            end)
registerAction("G", function()
    resetLastSearch()
    if repeatCount0 > 0 then
        currCursorY = repeatCount0
    else
        currCursorY = #filelines
    end
    currFileOffset = 0
    currCursorX = 1
    currXOffset = 0
    while currCursorY > hig - 1 do
        currCursorY = currCursorY - 1
        currFileOffset = currFileOffset + 1
    end
    drawFile()
end)
registerActionMulti({{"w", "W"}}, function(lst)
    local var1 = lst[1]
    return (function ()
        resetLastSearch()
        for i = 1, repeatCount1, 1 do
            local begs = str.wordBeginnings(filelines[currCursorY + currFileOffset], not string.match(var1, "%u"))
            if begs[#begs] then
                if currCursorX + currXOffset < begs[#begs] then
                    currCursorX = currCursorX + 1
                    while not tab.find(begs, currCursorX + currXOffset) do
                        currCursorX = currCursorX + 1
                    end
                    while currCursorX + lineoffset > wid do
                        currCursorX = currCursorX - 1
                        currXOffset = currXOffset + 1
                    end
                    oldx = currCursorX + currXOffset
                    drawFile()
                end
            end
        end
    end)
end)
registerActionMulti({{"e", "E"}}, function(lst)
    local var1 = lst[1]
    return (function ()
        resetLastSearch()
        for i = 1, repeatCount1, 1 do
            local begs = str.wordEnds(filelines[currCursorY + currFileOffset], not string.match(var1, "%u"))
            if begs[#begs] then
                if currCursorX + currXOffset < begs[#begs] then
                    currCursorX = currCursorX + 1
                    while not tab.find(begs, currCursorX + currXOffset) do
                        currCursorX = currCursorX + 1
                    end
                    while currCursorX + lineoffset > wid do
                        currCursorX = currCursorX - 1
                        currXOffset = currXOffset + 1
                    end
                    drawFile()
                end
            end
        end
    end)
end)
registerActionMulti({{"b", "B"}}, function(lst)
    local var1 = lst[1]
    return (function ()
        resetLastSearch()
        for i = 1, repeatCount1, 1 do
            local begs = str.wordBeginnings(filelines[currCursorY + currFileOffset], not string.match(var1, "%u"))
            if begs[1] then
                if currCursorX + currXOffset > begs[1] then
                    currCursorX = currCursorX - 1
                    while not tab.find(begs, currCursorX + currXOffset) do
                        currCursorX = currCursorX - 1
                    end
                    while currCursorX < 1 do
                        currCursorX = currCursorX + 1
                        currXOffset = currXOffset - 1
                    end
                    oldx = currCursorX + currXOffset
                end
            end
        end
        drawFile()
    end)
end)
registerAction("^", function()
            lastSearchPos = nil
            lastSearchLine = nil
            currCursorX = 1
            currXOffset = 0
            local i = currCursorX
            while string.sub(filelines[currCursorY + currFileOffset], i, i) == " " and i < #filelines[currCursorY + currFileOffset] do
                i = i + 1
            end
            currCursorX = i
            while currCursorX + lineoffset > wid do
                currCursorX = currCursorX - 1
                currXOffset = currXOffset + 1
            end
            drawFile()
        end)
registerActionMulti({{"f", "t"}}, function(lst)
    local var1 = lst[1]
    return (function ()
        resetLastSearch()
        local c = pullTypeaheadCharMode("i")
        local idx = str.indicesOfLetter(filelines[currCursorY + currFileOffset], c)
        for i = 1, repeatCount1, 1 do
            if #idx > 0 then
                if currCursorX + currFileOffset < idx[#idx] - jumpoffset then
                    local oldcursor = currCursorX
                    currCursorX = currCursorX + (1 + jumpoffset)
                    while not tab.find(idx, currCursorX + currXOffset) and currCursorX + currXOffset < #filelines[currCursorY + currFileOffset] do
                        currCursorX = currCursorX + 1
                    end
                    if not tab.find(idx, currCursorX + currXOffset) then
                        currCursorX = oldcursor
                    end
                    if var1 == "t" then
                        currCursorX = currCursorX - 1
                    end
                    while currCursorX + lineoffset > wid do
                        currCursorX = currCursorX - 1
                        currXOffset = currXOffset + 1
                    end
                    drawFile()
                    jumpbuffer = {var1, c}
                    if var1 == "t" then
                        jumpoffset = 1
                    else
                        jumpoffset = 0
                    end
                end
            end
        end
    end)
end)
registerActionMulti({{"F", "T"}}, function(lst)
    local var1 = lst[1]
    return (function ()
            resetLastSearch()
            local c = pullTypeaheadCharMode("i")
            local idx = str.indicesOfLetter(filelines[currCursorY + currFileOffset], c)
            -- TODO Figure out if the lack of repetition is intentional
            if #idx > 0 then
                if currCursorX + currFileOffset > idx[1] + jumpoffset then
                    currCursorX = currCursorX - (1 + jumpoffset)
                    while not tab.find(idx, currCursorX + currXOffset) and currCursorX > 1 do
                        currCursorX = currCursorX - 1
                    end
                    if var1 == "T" then
                        currCursorX = currCursorX + 1
                    end
                    while currCursorX < 1 do
                        currCursorX = currCursorX + 1
                        currXOffset = currXOffset - 1
                    end
                    drawFile()
                    jumpbuffer = {var1, c}
                    if var1 == "T" then
                        jumpoffset = 1
                    else
                        jumpoffset = 0
                    end
                end
            end
        end)
    end)
registerActionMulti({{"F", "T"}}, function(lst)
    local var1 = lst[1]
    return (function ()
            lastSearchPos = nil
            lastSearchLine = nil
            if jumpbuffer[1] then
                local tx = jumpbuffer[1]
                if var1 == "," then
                    if string.match(tx, "%u") then
                        tx = string.lower(tx)
                    else
                        tx = string.upper(tx)
                    end
                end
                if string.match(tx, "%u") then
                    local c = jumpbuffer[2]
                    local idx = str.indicesOfLetter(filelines[currCursorY + currFileOffset], c)
                    if #idx > 0 then
                        if currCursorX + currFileOffset > idx[1] + jumpoffset then
                            currCursorX = currCursorX - (1 + jumpoffset)
                            while not tab.find(idx, currCursorX + currXOffset) do
                                currCursorX = currCursorX - 1
                            end
                            if jumpbuffer[1] == "T" or jumpbuffer[1] == "t" then
                                currCursorX = currCursorX + 1
                            end
                            while currCursorX < 1 do
                                currCursorX = currCursorX + 1
                                currXOffset = currXOffset - 1
                            end
                            drawFile()
                        end
                    end
                else
                    local c = jumpbuffer[2]
                    local idx = str.indicesOfLetter(filelines[currCursorY + currFileOffset], c)
                    if #idx > 0 then
                        if currCursorX + currFileOffset < idx[#idx] - jumpoffset then
                            local oldcursor = currCursorX
                            currCursorX = currCursorX + (1 + jumpoffset)
                            while not tab.find(idx, currCursorX + currXOffset) and currCursorX + currXOffset ~= #filelines[currCursorY + currFileOffset] do
                                currCursorX = currCursorX + 1
                            end
                            if not tab.find(idx, currCursorX + currXOffset) then
                                currCursorX = oldcursor
                            end
                            if jumpbuffer[1] == "t" or jumpbuffer[1] == "T" then
                                currCursorX = currCursorX - 1
                            end
                            while currCursorX + lineoffset > wid do
                                currCursorX = currCursorX - 1
                                currXOffset = currXOffset + 1
                            end
                            drawFile()
                        end
                    end
                end
            end
        end)
    end)
registerAction("cc", function() resetLastSearch()
                filelines[currCursorY + currFileOffset] = ""
                currCursorX = 1
                currXOffset = 0
                recalcMLCs()
                drawFile()
                fileContents[currfile]["unsavedchanges"] = true
                insertMode()
            end)
registerAction("c$", function() resetLastSearch()
                filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1)
                recalcMLCs()
                drawFile()
                fileContents[currfile]["unsavedchanges"] = true
                insertMode()
            end)
registerAction("ciw", function() resetLastSearch()
                    local word,beg,ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                    filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, beg - 1) .. string.sub(filelines[currCursorY + currFileOffset], ed + 1, #filelines[currCursorY + currFileOffset])
                    currCursorX = beg
                    currXOffset = 0
                    while currCursorX + lineoffset > wid do
                        currCursorX = currCursorX - 1
                        currXOffset = currXOffset + 1
                    end
                    recalcMLCs()
                    drawFile()
                    fileContents[currfile]["unsavedchanges"] = true
                    insertMode()
                end)
registerActionMulti({{"cw", "ce"}}, function(_)
    return function() resetLastSearch()
                local word, beg, ed = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset)
                filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1).. string.sub(filelines[currCursorY + currFileOffset], ed + 1, #filelines[currCursorY + currFileOffset])
                recalcMLCs()
                drawFile()
                fileContents[currfile]["unsavedchanges"] = true
                insertMode()
            end
        end)
registerAction("C", function()
            filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1)
            recalcMLCs()
            drawFile()
            fileContents[currfile]["unsavedchanges"] = true
            insertMode()
        end)
registerAction("s", function()
            filelines[currCursorY + currFileOffset] = string.sub(filelines[currCursorY + currFileOffset], 1, currCursorX + currXOffset - 1) .. string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset + 1, #filelines[currCursorY + currFileOffset])
            recalcMLCs()
            drawFile()
            if not fileContents[currfile] then
                fileContents[currfile] = {""}
            end
            fileContents[currfile]["unsavedchanges"] = true
            insertMode()
        end)
registerAction("S", function()
            lastSearchPos = nil
            lastSearchLine = nil
            filelines[currCursorY + currFileOffset] = ""
            currCursorX = 1
            currXOffset = 0
            recalcMLCs()
            drawFile()
            fileContents[currfile]["unsavedchanges"] = true
            insertMode()
        end)
registerAction("%", function()
            lastSearchPos = nil
            lastSearchLine = nil
            local startpos = {currCursorX, currXOffset, currCursorY, currFileOffset}
            local startbracket = string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset)
            local endbracket = ""
            if startbracket == "(" then
                endbracket = ")"
            elseif startbracket == "{" then
                endbracket = "}"
            elseif startbracket == "[" then
                endbracket = "]"
            else
                endbracket = nil
            end
            if endbracket then
                local extrabrackets = 0
                local continuefor = true
                currCursorX = currCursorX + 1
                setcolors(colors.black, colors.white)
                for i=currCursorY + currFileOffset,#filelines,1 do
                    if continuefor then
                        while currCursorX + currXOffset <= #filelines[currCursorY + currFileOffset] do
                            if string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset) == startbracket then
                                extrabrackets = extrabrackets + 1
                            elseif string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset) == endbracket then
                                if extrabrackets > 0 then
                                    extrabrackets = extrabrackets - 1
                                else
                                    extrabrackets = extrabrackets - 1
                                end
                            end
                            currCursorX = currCursorX + 1
                        end
                        if (string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset) == endbracket and extrabrackets == 0) or extrabrackets < 0 then
                            if currCursorX > 1 then
                                currCursorX = currCursorX - 1
                            end
                            continuefor = false
                        else
                            currCursorX = 1
                            currXOffset = 0
                            if #filelines > 1 then
                                currCursorY = currCursorY + 1
                            end
                        end
                    end
                end
            end
            while currCursorX < 1 do
                currCursorX = currCursorX + 1
                currXOffset = currXOffset - 1
            end
            while currCursorX > wid - lineoffset do
                currCursorX = currCursorX - 1
                currXOffset = currXOffset + 1
            end
            while currCursorY > hig - 1 do
                currCursorY = currCursorY - 1
                currFileOffset = currFileOffset + 1
            end
            drawFile(true)
            if not string.sub(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, currCursorX + currXOffset) == endbracket then
                currCursorX = startpos[1]
                currXOffset = startpos[2]
                currCursorY = startpos[3]
                currFileOffset = startpos[4]
            end
        end)
registerAction("/", function()
            search("forward")
        end)
registerAction("?", function()
            search("backward")
        end)
registerAction("n", function()
            search("forward", true)
        end)
registerAction("N", function()
            search("backward", true)
        end)
registerAction("*", function()
            local currword = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, true)
            search("forward", false, currword)
        end)
registerAction("#", function()
            local currword = str.wordOfPos(filelines[currCursorY + currFileOffset], currCursorX + currXOffset, true)
            search("backward", false, currword)
        end)
-- TODO also handle repetitions
registerAction("<left>", moveCursorLeft)
registerAction("<right>", function() moveCursorRight(1) end)
registerAction("<up>", moveCursorUp)
registerAction("<down>", moveCursorDown)

registerAction("<C-u>", function()
    if repeatCount0 > 0 then
        scrollOption = repeatCount0
    end
    scrollWindowY(-scrollOption, true)
end)
registerAction("<C-d>", function()
    if repeatCount0 > 0 then
        scrollOption = repeatCount0
    end
    scrollWindowY(scrollOption, true)
end)
registerAction("<C-b>", function()
    local multiplier = hig - 3
    if multiplier < 1 then
        multiplier = 1
    end
    local amount = multiplier * repeatCount1 + 2
    scrollWindowY(-amount, false)
end)
registerAction("<C-f>", function()
    local multiplier = hig - 3
    if multiplier < 1 then
        multiplier = 1
    end
    local amount = multiplier * repeatCount1 + 2
    scrollWindowY(amount, false)
end)
registerAction("<C-y>", function()
    scrollWindowY(-repeatCount1, false)
end)
registerAction("<C-e>", function()
    scrollWindowY(repeatCount1, false)
end)
registerAction("<scrollwheelup>", function()
    scrollWindowY(-repeatCount1 * 3, false)
end)
registerAction("<scrollwheeldown>", function()
    scrollWindowY(repeatCount1 * 3, false)
end)
registerAction("<S-scrollwheelup>", function()
    local multiplier = hig - 3
    if multiplier < 1 then
        multiplier = 1
    end
    local amount = multiplier * repeatCount1 + 2
    scrollWindowY(-amount, false)
end)
registerAction("<S-scrollwheeldown>", function()
    local multiplier = hig - 3
    if multiplier < 1 then
        multiplier = 1
    end
    local amount = multiplier * repeatCount1 + 2
    scrollWindowY(amount, false)
end)
registerAction("<pageup>", function()
    local multiplier = hig - 3
    if multiplier < 1 then
        multiplier = 1
    end
    local amount = multiplier * repeatCount1 + 2
    scrollWindowY(-amount, false)
end)
registerAction("<pagedown>", function()
    local multiplier = hig - 3
    if multiplier < 1 then
        multiplier = 1
    end
    local amount = multiplier * repeatCount1 + 2
    scrollWindowY(amount, false)
end)

registerAction("<leftmouse>", function()
    resetLastSearch()
    currCursorX = inputProperties.mouseX - lineoffset
    currCursorY = inputProperties.mouseY
    if currCursorY + currFileOffset > #filelines then
        currCursorY = #filelines - currFileOffset
    end
    local line = filelines[currCursorY + currFileOffset]
    oldx = currCursorX + currXOffset
    if line and #line < currCursorX + currXOffset then
        currCursorX = #line - currXOffset
    end
    redrawTerm()
end)

-- By default paste content is interpreted as normal-mode keys, use mappings to change this behavior
registerAction("<C-S-v>", function()
    expandPaste()
end)

while running == true do
    local cons = actionsTrie:consumer()
    local i = 0
    local prefix = {}
    local countStr = pullCount()
    if #countStr > 0 then
        repeatCount0 = tonumber(countStr)
        repeatCount1 = repeatCount0
    else
        repeatCount0 = 0
        repeatCount1 = 1
    end
    while true do
        i = i + 1
        local key
        if i == 1 then
            key = peekTypeaheadWRMP(i)
        else
            key = peekTypeahead(i)
        end
        if key == "C-c" then
            -- Clear typeahead
            for _ = 1, i do
                pullTypeahead()
            end
            cons = nil
            break
        end
        prefix[i] = key
        if not cons:next(key) then
            break
        end
        if not cons:hasNext() then
            break
        end
    end
    if cons ~= nil then
        local len, action = cons:getDeepest()
        if len > 0 then
            for _ = 1, len do
                pullTypeahead()
            end
            action()
        else
            -- Drop one key
            pullTypeahead()
        end
    end
end
