-- Small deterministic helpers shared by the model, local storage and UI.
local U = {}

function U.copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = U.copy(child) end
    return out
end

function U.finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function U.integer(value, low, high)
    return U.finite(value) and value % 1 == 0
        and value >= low and value <= high
end

-- Native ID indexes enumerate numeric keys and name strings in this beta;
-- ordinary Lua test/older indexes can instead contain name -> numeric ID.
-- Resolve by the exposed name, rather than assuming the numeric key is an ID.
function U.namedID(index, key, value)
    if type(key) == "string" and U.integer(value, -2147483648, 2147483647) then return key, value end
    if type(value) ~= "string" then return end
    local ok, id = pcall(function() return index[value] end)
    if ok and U.integer(id, -2147483648, 2147483647) then return value, id end
end

-- The client sandbox does not provide Lua's optional utf8 library. Count valid
-- Unicode scalars directly, rejecting overlong encodings, surrogates and values
-- above U+10FFFF. This is validation of our own form/storage text, not key input.
function U.textLength(value)
    if type(value) ~= "string" then return nil end
    local index, count = 1, 0
    while index <= #value do
        local first, length = value:byte(index), 1
        if first >= 0xC2 and first <= 0xDF then length = 2
        elseif first >= 0xE0 and first <= 0xEF then length = 3
        elseif first >= 0xF0 and first <= 0xF4 then length = 4
        elseif first >= 0x80 then return nil end
        for offset = 1, length - 1 do
            local continuation = value:byte(index + offset)
            if not continuation or continuation < 0x80 or continuation > 0xBF then return nil end
        end
        local second = value:byte(index + 1)
        if (first == 0xE0 and second < 0xA0) or (first == 0xED and second > 0x9F)
            or (first == 0xF0 and second < 0x90) or (first == 0xF4 and second > 0x8F) then return nil end
        count, index = count + 1, index + length
    end
    return count
end

function U.text(value, limit)
    if type(value) ~= "string" or #value > limit * 4 or value:find("%z")
        or value:find("[\1-\8\11\12\14-\31]") then return false end
    local length = U.textLength(value)
    return length ~= nil and length <= limit
end

function U.named(value, limit)
    return U.text(value, limit) and value:find("%S") ~= nil
end

-- Compare validated structured records before writing shared device storage.
function U.equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not U.equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

function U.array(value, maximum)
    if type(value) ~= "table" or (maximum ~= nil and #value > maximum) then return false end
    local count = 0
    for key in pairs(value) do
        if not U.integer(key, 1, #value) then return false end
        count = count + 1
    end
    return count == #value
end

function U.fields(value, allowed)
    if type(value) ~= "table" then return false end
    for key in pairs(value) do
        if not allowed[key] then return false end
    end
    return true
end

function U.clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

-- Keep the last UTF-8 character intact when migrating a byte-limited caption.
function U.shortText(value, limit)
    local text = tostring(value)
    if #text <= limit then return text end
    local cut = limit + 1
    while cut > 1 and text:byte(cut) and text:byte(cut) >= 128 and text:byte(cut) < 192 do cut = cut - 1 end
    return text:sub(1, cut - 1)
end

-- Accent-insensitive search over our four supported UI languages.
function U.fold(value)
    -- string.lower follows the host C locale and can corrupt UTF-8 on Windows.
    local text = tostring(value):gsub("[A-Z]", function(ch) return string.char(ch:byte() + 32) end)
    for _, group in ipairs({ { "a", "ÀÁÂÃÄÅàáâãäå" }, { "e", "ÈÉÊËèéêë" },
        { "i", "ÌÍÎÏìíîï" }, { "o", "ÒÓÔÕÖòóôõö" }, { "u", "ÙÚÛÜùúûü" },
        { "c", "Çç" }, { "n", "Ññ" } }) do
        for character in group[2]:gmatch("[\194-\244][\128-\191]+") do text = text:gsub(character, group[1]) end
    end
    -- Copied text may encode the same accent as a separate U+0300..U+036F
    -- combining mark. Search folding handles both forms; physical key parsing
    -- still preserves accented key glyphs instead of folding them to ASCII.
    return (text:gsub("\204[\128-\191]", ""):gsub("\205[\128-\175]", "")
        :gsub("ẞ", "ss"):gsub("ß", "ss"):gsub("Œ", "oe"):gsub("œ", "oe"))
end

-- User text is displayed literally rather than interpreted as RuneScape markup.
function U.display(text)
    return (tostring(text or ""):gsub("<", "‹"):gsub(">", "›"))
end

return U
