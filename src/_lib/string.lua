if DO_NOT_RUN then return end

---@param s string
---@param sep string?
---@return string[]
function string.split(s, sep)
    local parts = {}
    local pattern = "%S+"
    if sep ~= nil then pattern = "([^" .. sep .. "]+)" end
    for part in string.gmatch(s, pattern) do
        table.insert(parts, part)
    end
    return parts
end

---@param s string
---@return string
function string.strip_colors(s)
    local stripped = string.gsub(s, "\\#%x+\\", "")
    return stripped
end

---@param n integer
---@param digits integer?
---@return string
function string.to_hex(n, digits)
    if digits ~= nil then
        return string.format("%" .. tostring(digits) .. "x", n)
    end
    return string.format("%x", n)
end
