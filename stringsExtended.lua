
--- Extends Lua's builtin string library to add Python's .split method<br>
--- OVERLOADED METHOD: Returns an array of strings resulting from splitting the original string on a delimiter.
--- If no delimiter is passed, returns the string split on whitespace.
---@param str any @the string to split
---@param ... any @the delimiter to split on
---@return table @the split elements
function string.split(str, ...)
    local args = {...}
    local delim = args[1] or "%s"
    local out = {}
    local i = 1
    while str do
        local part, remainder = string.match(str, string.format("(.-)%s+(.*)", delim))
        if part then
            out[i] = part
            str = remainder
            i = i + 1
        else
            out[i] = str
            break
        end
    end

    return out
end

--- Extends Lua's builtin string library to include Python's .split method.<br>
--- OVERLOADED METHOD: Returns the first parameter stripped of all leading and trailing occurrences of the second (if present).
--- If no second parameter is passed, returns the first parameter stripped of leading and trailing spaces.
---@param str string @The string to strip
---@param ... string @The pattern to strip from string
---@return string @The string stripped of leading and trailing occurrences of pattern, if provided, stripped of leading and trailing spaces if not.
function string.strip(str, ...)
    local args = {...}
    local pattern = args[1] or "%s"
    local stripped = str:match(string.format("^%s*(.-)%s*$", pattern))
    return stripped
end

--- Extends Lua's builtin string library to include Python's .lstrip method.<br>
--- OVERLOADED METHOD: Returns the first parameter stripped of all leading occurences of any character present in the second.
--- Continues stripping characters until no occurence of any character in elements remains at the beginning of the string.<br>
--- In other words, string.lstrip("abacc", "ab") returns "cc", not "acc".<br>
--- If no argument is provided, returns the string with leading whitespace stripped.
--- @param str string @The string to strip
--- @param ... string @A string containing all the elements to strip.
function string.lstrip(str, ...)
    local args = (...)
    local elements = args[1] or "%s"
    repeat str = str:match(string.format("^[%s]+(.+$)", elements))
    until str:match(string.format("^[%s](.+$)", elements)) == nil
    return str
end

--- Extends Lua's builtin string library to include Python's .lstrip method.<br>
--- OVERLOADED METHOD: Returns the first parameter stripped of all trailing  occurences of any character present in the second.
--- Continues stripping characters until no occurence of any character in elements remains at the end of the string.<br>
--- In other words, string.rstrip("abcac", "ac") returns "ab", not "abc".<br>
--- If no argument is provided, returns the string stripped of trailing whitespace.
--- @param str string @The string to strip
--- @param ... string @A string containing all the elements to strip.
function string.rstrip(str, ...)
    local args = (...)
    local elements = args[1] or "%s"
    repeat str = str:match(string.format("^(.+$)[%s]", elements))
    until str:match(string.format("^(.+$)[%s]", elements)) == nil
    return str
end


return {string = string}