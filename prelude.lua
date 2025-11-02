--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Prelude


--[[
local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= "nil" then return end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
end
]]

---@param triggerId string
---@param moduleName string
---@return any
local function import(triggerId, moduleName)
  local source = getLoreBooks(triggerId, moduleName)
  if not source or #source == 0 then
    error('Failed to load module: ' .. moduleName)
  end
  local chunk, err = load(source[1].content, '@' .. moduleName, 't')
  if not chunk then
    error('Error loading module ' .. moduleName .. ': ' .. err)
  end
  return chunk()
end

---@param str string
---@return string
local function trim(str)
  -- Remove leading whitespace (%s* at the start ^)
  str = string.gsub(str, "^%s*", "")
  -- Remove trailing whitespace (%s* at the end $)
  str = string.gsub(str, "%s*$", "")
  return str
end

---@param str string
---@return string
local function escEntities(str)
  if not str then
    return ""
  end

  str = str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&#34;"):gsub("'", "&#39;"):gsub("\\n",
    "<br>")
  return str
end

---@param str string
---@return string
local function escMatch(str)
  str = str:gsub("(%W)", "%%%1")
  return str
end

---@param str string
---@return string
local function escQuotes(str)
  if not str then
    return ""
  end
  local result = {}
  for character in str:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
    if character == '"' or character == "“" or character == "”" then
      table.insert(result, "&#34;")
    elseif character == "'" or character == "‘" or character == "’" then
      table.insert(result, "&#39;")
    else
      table.insert(result, character)
    end
  end
  return table.concat(result)
end

---Extracts contents between all [Tag] ... [Tag].
---@param tag string
---@param content string
---@param tagToEnd string[]?
---@return string[]
local function extractBlocks(tag, content, tagToEnd)
  local results = {}
  local openTag = "[" .. tag .. "]"
  local pos = 1

  while true do
    local s, e = content:find(openTag, pos, true)
    if not s then break end

    -- find next occurrence of the same tag
    local nextS = content:find(openTag, e + 1, true)
    local blockContent
    if nextS then
      blockContent = content:sub(e + 1, nextS - 1)
      pos = nextS
    else
      -- last segment
      blockContent = content:sub(e + 1)
    end

    -- Apply tagToEnd logic
    if type(tagToEnd) == "table" then
      for _, endTag in ipairs(tagToEnd) do
        if endTag and endTag ~= "" then
          local currentPattern = "%[" .. endTag:gsub("(%W)", "%%%1") .. "%]"
          local tagStartMatch = blockContent:find(currentPattern)
          if tagStartMatch then
            blockContent = blockContent:sub(1, tagStartMatch - 1)
            break
          end
        end
      end
    end

    table.insert(results, blockContent)

    if not nextS then break end
  end

  return results
end

---@class Node
---@field attributes table<string, string>
---@field content string
---@field rangeEnd number
---@field rangeStart number

---Extracts all nodes.
---@param text string
---@return Node[]
local function extractNodes(tagNameRaw, text)
  local results = {}
  local i = 1

  local tagName = tagNameRaw:gsub("(%W)", "%%%1")

  while true do
    local startIdx = text:find("<" .. tagName, i)
    if not startIdx then
      break
    end

    -- Find where the opening tag ends
    local tagEnd = text:find(">", startIdx)
    if not tagEnd then
      i = startIdx + 1
      goto continue
    end

    -- Extract all attributes from the opening tag
    local openTagContent = text:sub(
      startIdx + #("<" .. tagNameRaw),
      tagEnd - 1
    )
    local attrs = {}

    -- quoted attributes: key="val" or key='val'
    for key, _, val in openTagContent:gmatch("([%w:_-]+)%s*=%s*(['\"])(.-)%2") do
      attrs[key] = val
    end

    -- unquoted attributes: key=val
    for key, val in openTagContent:gmatch("([%w:_-]+)%s*=%s*([^%s\"'>]+)") do
      if not attrs[key] then attrs[key] = val end
    end

    -- boolean attributes: key (without value)
    -- First, remove all already parsed attributes to avoid conflicts
    local tempContent = openTagContent
    -- Remove quoted attributes
    tempContent = tempContent:gsub("([%w:_-]+)%s*=%s*(['\"])(.-)%2", "")
    -- Remove unquoted attributes
    tempContent = tempContent:gsub("([%w:_-]+)%s*=%s*([^%s\"'>]+)", "")
    -- Now find standalone attribute names
    for key in tempContent:gmatch("([%w:_-]+)") do
      if key and key ~= "" and not attrs[key] then
        attrs[key] = "true"
      end
    end

    -- Find closing tag
    local closeStart, _ = text:find("</" .. tagName .. ">", tagEnd)
    if not closeStart then
      i = tagEnd + 1
      goto continue
    end
    local closeEnd = closeStart + #("</" .. tagNameRaw .. ">") - 1

    -- Extract inner content
    local contentOnly = text:sub(tagEnd + 1, closeStart - 1)

    table.insert(results, {
      attributes = attrs,
      content    = contentOnly,
      rangeEnd   = closeEnd,
      rangeStart = startIdx,
    })

    i = closeEnd + 1
    ::continue::
  end

  return results
end

---Get a lore book with the highest insert order.
---@param triggerId string
---@param name string
---@return LoreBook?
local function getPriorityLoreBook(triggerId, name)
  local books = getLoreBooks(triggerId, name)
  if not books or #books == 0 then
    return nil
  end

  table.sort(books, function(a, b)
    return (a.insertorder or 0) > (b.insertorder or 0)
  end)

  return books[1]
end

---Heals broken UTF-8 sequences in <0xXX> format.
---@param str string
---@return string
local function killGuim(str)
  local out, buf = {}, {}
  local function flush()
    if #buf > 0 then
      local s = string.char(table.unpack(buf))
      if utf8.len(s) then
        out[#out + 1] = s
      else
        for _, b in ipairs(buf) do
          out[#out + 1] = string.format("<0x%02x>", b)
        end
      end
      buf = {}
    end
  end
  local i = 1
  while true do
    local s, e, hex = str:find("<0x(%x%x)>", i)
    if not s then break end
    if s > i then
      flush()
      out[#out + 1] = str:sub(i, s - 1)
    end
    buf[#buf + 1] = tonumber(hex, 16)
    i = e + 1
  end
  flush()
  if i <= #str then out[#out + 1] = str:sub(i) end
  return table.concat(out)
end

---Parses a block into a proper table.
---@param block string
---@param tagToEnd string[]?
---@return table
local function parseBlock(block, tagToEnd)
  local metadata = {}

  if type(tagToEnd) == "table" then
    for _, tag in ipairs(tagToEnd) do
      if tag and tag ~= "" then
        local currentPattern = "%[" .. tag:gsub("(%W)", "%%%1") .. "%]"
        local tagStartMatch = block:find(currentPattern)
        if tagStartMatch then
          block = block:sub(1, tagStartMatch - 1)
          break
        end
      end
    end
  end

  for part in block:gmatch("([^|]+)") do
    local field, value = part:match("([^:]+):(.+)")
    if field and value then
      field = trim(field)
      value = trim(value)
      metadata[field] = value
    end
  end

  return metadata
end

---@param str string
---@param sep string
---@return string[]
local function split(str, sep)
  local result = {}
  if not str then
    return result
  end

  if sep == "" then
    result[1] = str
    return result
  end

  local start = 1
  local idx = 1
  while true do
    local s, e = str:find(sep, start, true)
    if not s then
      result[idx] = str:sub(start)
      break
    end
    result[idx] = str:sub(start, s - 1)
    start = e + #sep
    idx = idx + 1
  end

  return result
end

_ENV.prelude = {
  escEntities = escEntities,
  escMatch = escMatch,
  escQuotes = escQuotes,
  extractBlocks = extractBlocks,
  extractNodes = extractNodes,
  getPriorityLoreBook = getPriorityLoreBook,
  import = import,
  killGuim = killGuim,
  parseBlock = parseBlock,
  split = split,
  trim = trim
}

local gen_mt, tag_mt, safe_mt

local function rawHTML(html)
  if type(html) == "string" then
    return setmetatable({
      html = html
    }, safe_mt)
  else
    return
  end
end

-- get printable HTML, escaping unless marked to be used raw
local function safeHTML(text)
  if getmetatable(text) == safe_mt then
    return text.html
  end

  return escEntities(text)
end

-- create HTML from a table
local function genHTML(tag, content)
  -- convenience; can call with table or string parameter
  if type(content) == "string" then
    return genHTML(tag, { content })
  end

  local name = tag._name:gsub("_", "-")
  local tagClass = tag._class

  content.class = content.class and ((tagClass or " ") .. content.class) or tagClass or nil

  local attTable = {}
  local bodyTable = {}
  for k, v in pairs(content) do
    local t = type(k)
    if t == "string" and k ~= "closed" and not k ~= "void" then
      if k == "htmlFor" then
        k = "for"
      end

      attTable[#attTable + 1] = ('%s="%s"'):format(k:gsub("_", "-"), safeHTML(tostring(v)))
    elseif not content.void and not content.closed and t == "number" then
      local vt = type(v)
      if vt == "table" and getmetatable(v) ~= safe_mt then
        for _, child in ipairs(v) do
          bodyTable[#bodyTable + 1] = safeHTML(child)
        end
      elseif vt ~= "nil" then
        bodyTable[#bodyTable + 1] = safeHTML(v)
      end
    end
  end

  local atts = table.concat(attTable, " ")
  if #atts > 0 then atts = " " .. atts end

  local body = table.concat(bodyTable)

  if content.void then
    return rawHTML(("<%s%s>"):format(name, atts))
  end

  if content.closed then
    return rawHTML(("<%s%s />"):format(name, atts))
  end

  local html = ("<%s%s>%s</%s>"):format(name, atts, body, name)
  return rawHTML(html)
end

gen_mt = {
  __index = function(context, name)
    local tag = setmetatable({
      _name = name,
      _class = false
    }, tag_mt)
    context[name] = tag
    return tag
  end
}

tag_mt = {
  __call = genHTML,
  __index = function(tag, class)
    local tagWithClass = setmetatable({
      _name = tag._name,
      _class = class
    }, tag_mt)

    tag[class] = tagWithClass
    return tagWithClass
  end
}

safe_mt = {
  __tostring = function(self)
    return self.html
  end
}

local function hx()
  return setmetatable({}, gen_mt)
end

_ENV.h = hx()
_ENV.hraw = rawHTML
