--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Guide

--- @param s string
--- @return string
local function trim(s)
  -- Remove leading whitespace (%s* at the start ^)
  s = string.gsub(s, "^%s*", "")
  -- Remove trailing whitespace (%s* at the end $)
  s = string.gsub(s, "%s*$", "")
  return s
end

---Extracts all nodes.
---@param text string
---@return table[]
local function extractAllNodes(tagNameRaw, text)
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
    for key, quote, val in openTagContent:gmatch("([%w:_-]+)%s*=%s*(['\"])(.-)%2") do
      attrs[key] = val
    end

    -- unquoted attributes: key=val
    for key, val in openTagContent:gmatch("([%w:_-]+)%s*=%s*([^%s\"'>]+)") do
      if not attrs[key] then attrs[key] = val end
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
      content    = contentOnly,
      attributes = attrs,
      rangeStart = startIdx,
      rangeEnd   = closeEnd
    })

    i = closeEnd + 1
    ::continue::
  end

  return results
end

---Extracts contents between all [Tag] ... [Tag].
---@param tag string
---@param content string
---@return string[]
local function extractBlocks(tag, content)
  local results = {}
  local openTag = "[" .. tag .. "]"
  local pos = 1

  while true do
    local s, e = content:find(openTag, pos, true)
    if not s then break end

    -- find next occurrence of the same tag
    local nextS = content:find(openTag, e + 1, true)
    if nextS then
      table.insert(results, content:sub(e + 1, nextS - 1))
      pos = nextS
    else
      -- last segment
      table.insert(results, content:sub(e + 1))
      break
    end
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

  local contentMatch = block:match("Content:(.-)$")
  if contentMatch then
    metadata["Content"] = trim(contentMatch)
    block = block:gsub("Content:.*$", "")
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
---@return string
local function escapeHtml(str)
  if not str then
    return ""
  end
  str = string.gsub(str, "&", "&amp;")
  str = string.gsub(str, "<", "&lt;")
  str = string.gsub(str, ">", "&gt;")
  return str
end

local function escapeQuotes(str)
  if not str then
    return ""
  end
  str = string.gsub(str, '"', "&quot;")
  str = string.gsub(str, "'", "&#39;")
  return str
end

---Renders a node into HTML.
---@param block table
---@return string
local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  -- Extract Review
  local reviewBlockStrings = extractBlocks("Review", rawContent)
  if not reviewBlockStrings or #reviewBlockStrings == 0 then
    -- If no [Review] block, maybe it's not for this component or malformed
    -- For now, let's return an empty string or an error message
    return "[LightBoard Guide: Missing Review block]"
  end
  local reviewData = parseBlock(reviewBlockStrings[1], { "Direction" })

  -- Extract Directions
  local directionBlockStrings = extractBlocks("Direction", rawContent)
  local directionsData = {}
  for _, dirBlockString in ipairs(directionBlockStrings) do
    table.insert(directionsData, parseBlock(dirBlockString))
  end

  local html = {}

  table.insert(html,
    '<details class="lb-module-root lb-module-root-animated" name="lightboard-guide"><summary class="lb-opener"><span>가이드</span></summary>'
  )
  table.insert(html, '<div class="lb-guide-component-container">')

  -- Render Review Card
  if reviewData.Score and reviewData.Content then
    table.insert(html, '  <div class="lb-guide-review-card lb-guide-card">')
    table.insert(html, '    <span class="lb-guide-content">' .. escapeHtml(reviewData.Content) .. '</span>')
    table.insert(html, '    <div class="lb-guide-score-container">')
    table.insert(html, '      <div class="lb-guide-score-label">Confidence Score ' .. reviewData.Score .. '/5</div>')
    table.insert(html, '      <div class="lb-guide-score" data-value="' .. reviewData.Score .. '"></div>')
    table.insert(html, '    </div>')
    table.insert(html, '  </div>')
  end

  -- Render Directions Row
  if #directionsData > 0 then
    table.insert(html, '  <div class="lb-guide-directions-row">')
    local gradientClasses = { "lb-guide-gradient-1", "lb-guide-gradient-2", "lb-guide-gradient-3" }
    for i, dirData in ipairs(directionsData) do
      local gradientClass = gradientClasses[((i - 1) % #gradientClasses) + 1] -- Cycle through gradients
      table.insert(html,
        '    <button class="lb-guide-direction-card lb-guide-card" type="button" risu-btn="lb-guide__' ..
        escapeQuotes(escapeHtml(dirData.Content or "")) .. '">')
      table.insert(html, '      <div class="lb-guide-direction-keyword-header ' ..
        gradientClass .. '">' .. escapeHtml(dirData.Keywords or "Keywords") .. '</div>')
      table.insert(html, '      <div class="lb-guide-direction-card-body">')
      table.insert(html, '        <span class="lb-guide-outcome">' .. escapeHtml(dirData.Outcome or "") .. '</span>')
      table.insert(html, '        <span class="lb-guide-content">' .. escapeHtml(dirData.Content or "") .. '</span>')
      table.insert(html, '        <span class="lb-guide-why">' .. escapeHtml(dirData.Why or "") .. '</span>')
      table.insert(html, '        <span class="lb-guide-direction-score">' .. (dirData.Score or "?") .. '/5</span>')
      table.insert(html, '      </div>')
      table.insert(html, '    </button>')
    end
    table.insert(html, '  </div>') -- close lb-guide-directions-row
  end

  table.insert(html, '</div>')     -- close lb-guide-component-container
  table.insert(html, '</details>') -- close lb-module-root

  return table.concat(html, "\n")
end

local function main(_, data)
  if not data or data == "" then
    return ""
  end

  local output = ""
  local lastIndex = 1

  local success, extractionResult = pcall(extractAllNodes, "lightboard-guide", data)
  if success then
  else
    print("[LightBoard] Guide extraction failed:", tostring(extractionResult))
    return data
  end

  if extractionResult and #extractionResult > 0 then
    for i, match in ipairs(extractionResult) do
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      local processSuccess, renderResult = pcall(render, match)
      if processSuccess then
        output = output .. renderResult
      else
        print("[LightBoard] Guide parsing failed in block " .. i .. ":", tostring(renderResult))
        output = output .. "\n\n<!-- LightBoard Block Error -->"
      end
      lastIndex = match.rangeEnd + 1
    end
  else
    lastIndex = 1
  end

  if lastIndex <= #data then
    output = output .. data:sub(lastIndex)
  end

  return output
end

local function onButton(triggerId, code)
  local prefix = "lb%-guide__"
  local _, endIndex = string.find(code, prefix)
  if not endIndex then
    return
  end
  local body = code:sub(endIndex + 1)

  addChat(triggerId, "user", body)
  print("done")
end

onButtonClick = async(function(triggerId, code)
  local success, result = pcall(onButton, triggerId, code)
  if not success then
    print("[LightBoard] Guide button click failed:", tostring(result))
  end
  return result
end)

listenEdit(
  "editDisplay",
  function(triggerId, data)
    local success, result = pcall(main, triggerId, data)
    if success then
      return result
    else
      print("[LightBoard] Guide display failed:", tostring(result))
      return data
    end
  end
)
