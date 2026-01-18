--! Copyright (c) 2025-2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard Prelude


--[[!
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

local t_insert = table.insert

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
  if not str then return "" end

  local uspaces = {
    "\194\160",     -- NBSP
    "\227\128\128", -- Ideographic Space
    "\226\128\139", -- ZWSP
    "\239\187\191"  -- BOM
  }

  for _, seq in ipairs(uspaces) do
    str = str:gsub(seq, " ")
  end

  return str:match("^%s*(.-)%s*$") or ""
end

local ENTITIES = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&#34;",
  ["“"] = "&#34;",
  ["”"] = "&#34;",
  ["'"] = "&#39;",
  ["‘"] = "&#39;",
  ["’"] = "&#39;",
  ["\\n"] = "<br>"
}

---@param str string
---@return string
local function escEntities(str)
  if not str then return "" end
  str = (str:gsub("[&<>\"“ ”'‘’]", ENTITIES))
  str = str:gsub("\\n", ENTITIES["\\n"]) or str
  return str
end

---@param str string
---@return string
local function escMatch(str)
  str = str:gsub("(%W)", "%%%1")
  return str
end

---@param triggerId string
---@param flagName string
---@return boolean
local function getFlagToggle(triggerId, flagName)
  return getGlobalVar(triggerId, 'toggle_' .. flagName) == '1'
end

---@class Node
---@field attributes table<string, string>
---@field content string
---@field openTag string
---@field rangeEnd number
---@field rangeStart number
---@field tagName string

---Extracts all nodes.
---@param text string
---@return Node[]
local function queryNodes(tagNameRaw, text)
  local results = {}
  local i = 1

  local tagName = tagNameRaw:gsub("(%W)", "%%%1")

  while true do
    local startIdx = text:find("<" .. tagName, i)
    if not startIdx then
      break
    end

    local charAfter = text:sub(startIdx + #tagNameRaw + 1, startIdx + #tagNameRaw + 1)
    if charAfter ~= "" and not charAfter:match("[%s>/]") then
      i = startIdx + 1
    else
      -- Find where the opening tag ends
      local tagEnd = text:find(">", startIdx)
      if not tagEnd then
        i = startIdx + 1
      else
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

        -- Check if self-closing
        local isSelfClosing = openTagContent:match("/%s*$")

        if isSelfClosing then
          -- Self-closing tag: no content, rangeEnd is the closing >
          t_insert(results, {
            attributes = attrs,
            content    = "",
            openTag    = text:sub(startIdx, tagEnd),
            rangeEnd   = tagEnd,
            rangeStart = startIdx,
            tagName    = tagNameRaw,
          })
          i = tagEnd + 1
        else
          -- Find closing tag
          local closeStart, _ = text:find("</" .. tagName .. ">", tagEnd)
          if not closeStart then
            i = tagEnd + 1
          else
            local closeEnd = closeStart + #("</" .. tagNameRaw .. ">") - 1

            -- Extract inner content
            local contentOnly = text:sub(tagEnd + 1, closeStart - 1)

            t_insert(results, {
              attributes = attrs,
              content    = contentOnly,
              openTag    = text:sub(startIdx, tagEnd),
              rangeEnd   = closeEnd,
              rangeStart = startIdx,
              tagName    = tagNameRaw,
            })

            i = closeEnd + 1
          end
        end
      end
    end
  end

  return results
end

--- Removes all XML tagged blocks that is not <(tagsToKeep)> and without "keepalive" attribute.
--- @param text string
--- @param tagsToKeep string[]?
--- @return string
local function removeAllNodes(text, tagsToKeep)
  if not text then return "" end

  local sections = {}
  local position = 1

  local keepMap = nil
  if tagsToKeep then
    keepMap = {}
    for _, tag in ipairs(tagsToKeep) do
      keepMap[tag] = true
    end
  end

  while true do
    local tagStart = text:find("<", position)
    if not tagStart then break end

    local tagEnd = text:find(">", tagStart)
    if not tagEnd then
      position = tagStart + 1
    else
      local openTagContent = text:sub(tagStart + 1, tagEnd - 1)
      local foundTagName = openTagContent:match("^([%w%-%_]+)")

      if not foundTagName then
        position = tagEnd + 1
      else
        local hasKeepalive = openTagContent:match("%skeepalive[%s/]?$") or openTagContent:match("%skeepalive%s")
        local shouldKeep = (keepMap and keepMap[foundTagName]) or hasKeepalive
        local isSelfClosing = openTagContent:match("/%s*$")

        if isSelfClosing then
          if not shouldKeep then
            t_insert(sections, { start = tagStart, finish = tagEnd })
          end
          position = tagEnd + 1
        else
          local closePattern = "</" .. prelude.escMatch(foundTagName) .. ">"
          local closeStart, closeEnd = text:find(closePattern, tagEnd)

          if not closeStart then
            position = tagEnd + 1
          else
            if not shouldKeep then
              t_insert(sections, { start = tagStart, finish = closeEnd })
            end
            position = closeEnd + 1
          end
        end
      end
    end
  end

  if #sections == 0 then return text end

  table.sort(sections, function(a, b) return a.start < b.start end)

  local parts = {}
  local lastPos = 1

  for _, section in ipairs(sections) do
    local preText = text:sub(lastPos, section.start - 1)
    t_insert(parts, preText)

    -- 줄바꿈 중복 제거
    -- 조건: 방금 추가한 텍스트가 '\n'으로 끝나고, 삭제 후 이어질 텍스트가 '\n'으로 시작한다면?
    -- -> 이어질 텍스트의 시작 지점을 1칸 뒤로 미뤄서 '\n' 하나를 건너뜀.

    local endsWithNewline = false
    if #preText > 0 then
      endsWithNewline = (preText:sub(-1) == "\n")
    elseif #parts > 0 then
      -- preText가 비어있다면(연속된 태그 삭제 등), 그 전 조각을 확인해야 함
      local lastPart = parts[#parts]
      endsWithNewline = (lastPart:sub(-1) == "\n")
    end

    -- (2) 삭제 구간 바로 다음 글자가 \n 인지 확인
    local nextCharIsNewline = (text:sub(section.finish + 1, section.finish + 1) == "\n")

    if endsWithNewline and nextCharIsNewline then
      lastPos = section.finish + 2 -- 줄바꿈 하나 건너뛰고 이동
    else
      lastPos = section.finish + 1 -- 삭제 구간 바로 뒤로 이동
    end
  end

  t_insert(parts, text:sub(lastPos))

  return table.concat(parts)
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
    start = e + 1
    idx = idx + 1
  end

  return result
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

    t_insert(results, blockContent)

    if not nextS then break end
  end

  return results
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

_ENV.prelude = {
  escEntities = escEntities,
  escMatch = escMatch,
  extractNodes = queryNodes,
  getFlagToggle = getFlagToggle,
  getPriorityLoreBook = getPriorityLoreBook,
  import = import,
  queryNodes = queryNodes,
  removeAllNodes = removeAllNodes,
  split = split,
  trim = trim,
  -- deprecated
  extractBlocks = extractBlocks,
  parseBlock = parseBlock,
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

  return escEntities(tostring(text))
end

-- create HTML from a table
local function genHTML(tag, content)
  -- convenience; can call with table or string parameter
  if type(content) == "string" then
    return genHTML(tag, { content })
  end

  local name = tag._name:gsub("_", "-")
  local tagClass = tag._class

  if tagClass then
    content.class = content.class and (tagClass .. " " .. content.class) or tagClass
  end

  local attTable = {}
  local bodyTable = {}

  for k, v in pairs(content) do
    local kType = type(k)

    if kType == "number" then
      if not content.void and not content.closed then
        if type(v) == "table" and getmetatable(v) ~= safe_mt then
          -- 배열 형태의 자식 처리
          for _, child in ipairs(v) do
            t_insert(bodyTable, safeHTML(child))
          end
        elseif v ~= nil then
          t_insert(bodyTable, safeHTML(v))
        end
      end
    elseif kType == "string" then
      if k ~= "closed" and k ~= "void" then
        local attrName = k == "htmlFor" and "for" or k:gsub("_", "-")
        t_insert(attTable, string.format('%s="%s"', attrName, safeHTML(v)))
      end
    end
  end

  local atts = #attTable > 0 and (" " .. table.concat(attTable, " ")) or ""
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

return _ENV.prelude
