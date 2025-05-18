return function(tagNameRaw, text)
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
    local closeStart, _ = text:find("</" .. tagNameRaw .. ">", tagEnd)
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
