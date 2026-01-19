--! Copyright (c) 2025-2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard TOON Decode

local DEFAULT_CONFIG = {
  indent = 2
}

local function mergeConfig(options)
  local cfg = {}
  for k, v in pairs(DEFAULT_CONFIG) do
    cfg[k] = v
  end
  if options then
    for k, v in pairs(options) do
      if v ~= nil then
        cfg[k] = v
      end
    end
  end
  return cfg
end

local function unescapeString(str)
  local result = str:gsub("\\(.)", function(char)
    if char == "\\" then return "\\" end
    if char == "\"" then return "\"" end
    if char == "n" then return "\n" end
    if char == "r" then return "\r" end
    if char == "t" then return "\t" end
    error("Invalid escape sequence: \\" .. char)
  end)
  return result
end

-- Tokenize while respecting quotes/escapes; optionally capture first target char position
local function tokenize(line, delimiter, targetChar)
  local tokens, current = {}, {}
  local inQuotes, firstTarget = false, nil
  local i = 1

  local function push()
    table.insert(tokens, table.concat(current))
    current = {}
  end

  while i <= #line do
    local c = line:sub(i, i)

    if c == "\\" and i < #line then
      local nextC = line:sub(i + 1, i + 1)
      if inQuotes or nextC == "\"" or nextC == "\\" then
        table.insert(current, c .. nextC)
        i = i + 2
      else
        table.insert(current, c)
        i = i + 1
      end
    elseif c == "\"" then
      inQuotes = not inQuotes
      table.insert(current, c)
      i = i + 1
    elseif delimiter and not inQuotes and c == delimiter then
      push()
      i = i + 1
    else
      if not inQuotes and targetChar and not firstTarget and c == targetChar then
        firstTarget = i
      end
      table.insert(current, c)
      i = i + 1
    end
  end

  push()
  return tokens, firstTarget
end

local LITERALS = { ["true"] = true, ["false"] = false }

local function parseValue(token)
  if token:match('^".*"$') then
    return unescapeString(token:sub(2, -2))
  end

  if token == "null" then return nil end
  if LITERALS[token] ~= nil then return LITERALS[token] end

  if token:match("^0%d+$") then return token end

  local num = tonumber(token)
  if num then return num end

  return token:find("\\") and unescapeString(token) or token
end

local function assertKeyNotNil(key)
  if key == nil then
    error("Invalid key: null")
  end
  return key
end

local function splitValues(line, delimiter)
  return tokenize(line, delimiter)
end

local function findUnquotedChar(str, char)
  local _, pos = tokenize(str, nil, char)
  return pos
end

local function parseHeader(headerStr)
  local bracketStart = headerStr:find("%[")
  if not bracketStart then return nil end

  local beforeBracket = headerStr:sub(1, bracketStart - 1)

  local bracketEnd = headerStr:find("%]", bracketStart)
  if not bracketEnd then return nil end

  local bracketContent = headerStr:sub(bracketStart + 1, bracketEnd - 1)

  local afterBracket = headerStr:sub(bracketEnd + 1)
  if not afterBracket:match("^:") and not afterBracket:match("^{") then return nil end

  local lengthStr = bracketContent:match("^(%d+)")
  if not lengthStr then return nil end

  local delimiter = ","
  local delimStart = #lengthStr + 1
  if bracketContent:sub(1, 1) == "#" then
    delimStart = delimStart + 1
  end

  if delimStart <= #bracketContent then
    local delimChar = bracketContent:sub(delimStart, delimStart)
    if delimChar == "\t" then
      delimiter = "\t"
    elseif delimChar == "|" then
      delimiter = "|"
    end
  end

  local fields
  if afterBracket:sub(1, 1) == "{" then
    local braceEnd = findUnquotedChar(afterBracket:sub(2), "}")
    if braceEnd then
      braceEnd = braceEnd + 1
    end

    if braceEnd then
      local fieldsContent = afterBracket:sub(2, braceEnd - 1)
      if fieldsContent ~= "" then
        fields = {}
        local fieldTokens = splitValues(fieldsContent, delimiter)
        for _, token in ipairs(fieldTokens) do
          local trimmed = token:match("^%s*(.-)%s*$")
          if trimmed:match('^".*"$') then
            table.insert(fields, unescapeString(trimmed:sub(2, -2)))
          else
            table.insert(fields, trimmed)
          end
        end
      end
    end
  end

  return {
    key = beforeBracket ~= "" and beforeBracket or nil,
    delimiter = delimiter,
    fields = fields
  }
end

local function parseLines(text, config)
  local lines = {}
  for line in text:gmatch("[^\n]*") do
    table.insert(lines, line)
  end

  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end

  local parsed = {}
  for lineno, line in ipairs(lines) do
    if line ~= "" then
      local indent = #line:match("^( *)")
      local remainder = indent % config.indent
      if remainder ~= 0 then
        error(string.format('Line %d: Indentation must be exact multiple of %d, but found %d spaces.', lineno,
          config.indent, indent))
      end

      local depth = math.floor(indent / config.indent)
      local content = line:sub(indent + 1)

      table.insert(parsed, {
        depth = depth,
        content = content
      })
    end
  end

  return parsed
end

local decodeValue

local function parseTabularRows(lines, startIdx, targetDepth, headerInfo)
  local arr = {}
  local idx = startIdx

  while idx <= #lines and lines[idx].depth >= targetDepth do
    if lines[idx].depth == targetDepth then
      local rowLine = lines[idx]

      if rowLine.content:sub(1, 2) == "- " then
        break
      end

      local delimPos = findUnquotedChar(rowLine.content, headerInfo.delimiter)
      local colonPos = findUnquotedChar(rowLine.content, ":")

      if not delimPos and colonPos then
        break
      end

      local tokens = splitValues(rowLine.content, headerInfo.delimiter)
      local obj = {}
      for i, field in ipairs(headerInfo.fields) do
        obj[field] = parseValue(tokens[i] or "")
      end
      table.insert(arr, obj)
      idx = idx + 1
    else
      break
    end
  end

  return arr, idx
end

local function collectSiblings(obj, lines, startIdx, targetDepth, delimiter, config)
  local idx = startIdx

  while idx <= #lines and lines[idx].depth == targetDepth do
    local siblingLine = lines[idx]
    local sibHeaderInfo = parseHeader(siblingLine.content)

    if sibHeaderInfo and sibHeaderInfo.key then
      local arr
      arr, idx = decodeValue(lines, idx, targetDepth, config, delimiter, true)
      obj[sibHeaderInfo.key] = arr
    else
      local sibColonPos = findUnquotedChar(siblingLine.content, ":")
      if not sibColonPos then
        break
      end

      local sibValue = siblingLine.content:sub(sibColonPos + 1):match("^%s*(.-)%s*$")
      local sibParsedKey = assertKeyNotNil(parseValue(siblingLine.content:sub(1, sibColonPos - 1)))

      if sibValue == "" then
        local child
        child, idx = decodeValue(lines, idx + 1, targetDepth + 1, config, delimiter)
        obj[sibParsedKey] = child or {}
      else
        obj[sibParsedKey] = parseValue(sibValue)
        idx = idx + 1
      end
    end
  end

  return idx
end

local function decodeListItem(lines, startIdx, targetDepth, config, parentDelimiter)
  local delimiter = parentDelimiter or ","
  local itemContent = lines[startIdx].content:sub(3)

  if itemContent == "" then
    return {}, startIdx + 1
  end

  local headerInfo = parseHeader(itemContent)
  if headerInfo and not headerInfo.key then
    local arr = {}
    local colonPos = findUnquotedChar(itemContent, ":")
    if colonPos then
      local afterColon = itemContent:sub(colonPos + 1)
      if afterColon ~= "" then
        afterColon = afterColon:match("^%s*(.+)$") or afterColon
        local tokens = splitValues(afterColon, headerInfo.delimiter)
        for _, token in ipairs(tokens) do
          table.insert(arr, parseValue(token))
        end
      end
    end

    local idx = startIdx + 1
    while idx <= #lines and lines[idx].depth == targetDepth + 2 do
      local item, nextIdx = decodeValue(lines, idx, targetDepth + 2, config, headerInfo.delimiter)
      table.insert(arr, item)
      idx = nextIdx
    end

    return arr, idx
  end

  local colonPos = findUnquotedChar(itemContent, ":")
  if not colonPos then
    return parseValue(itemContent), startIdx + 1
  end

  local value = itemContent:sub(colonPos + 1):match("^%s*(.-)%s*$")
  local obj = {}
  local parsedKey = assertKeyNotNil(parseValue(itemContent:sub(1, colonPos - 1)))
  local idx = startIdx

  local keyHeaderInfo = headerInfo and headerInfo.key and headerInfo or nil
  if keyHeaderInfo then
    local arr = {}

    if value ~= "" then
      local tokens = splitValues(value, keyHeaderInfo.delimiter)
      for _, token in ipairs(tokens) do
        table.insert(arr, parseValue(token))
      end
    end

    if keyHeaderInfo.fields then
      local tabularArr
      tabularArr, idx = parseTabularRows(lines, startIdx + 1, targetDepth + 1, keyHeaderInfo)
      for _, row in ipairs(tabularArr) do
        table.insert(arr, row)
      end
    else
      idx = startIdx + 1
      while idx <= #lines and lines[idx].depth == targetDepth + 1 and lines[idx].content:sub(1, 2) == "- " do
        local item, nextIdx = decodeValue(lines, idx, targetDepth + 1, config, keyHeaderInfo.delimiter)
        table.insert(arr, item)
        idx = nextIdx
      end
    end

    obj[keyHeaderInfo.key] = arr
  elseif value == "" then
    obj[parsedKey], idx = decodeValue(lines, startIdx + 1, targetDepth + 2, config, delimiter)
    obj[parsedKey] = obj[parsedKey] or {}
  else
    obj[parsedKey] = parseValue(value)
    idx = startIdx + 1
  end

  local nextIdx = collectSiblings(obj, lines, idx, targetDepth + 1, delimiter, config)
  return obj, nextIdx
end

local function parseListArray(lines, startIdx, targetDepth, config, delimiter)
  local arr = {}
  local idx = startIdx

  while idx <= #lines and lines[idx].depth == targetDepth and lines[idx].content:sub(1, 2) == "- " do
    local item, nextIdx = decodeValue(lines, idx, targetDepth, config, delimiter)
    table.insert(arr, item)
    idx = nextIdx
  end

  return arr, idx
end

function decodeValue(lines, startIdx, targetDepth, config, parentDelimiter, expectValue)
  local delimiter = parentDelimiter or ","

  if startIdx > #lines then
    return nil, startIdx
  end

  local line = lines[startIdx]

  if line.depth ~= targetDepth then
    return nil, startIdx
  end

  local content = line.content

  if content:sub(1, 2) == "- " then
    return decodeListItem(lines, startIdx, targetDepth, config, delimiter)
  end

  local headerInfo = parseHeader(content)
  if headerInfo then
    if headerInfo.key and not expectValue then
      local obj = {}
      local nextIdx = collectSiblings(obj, lines, startIdx, targetDepth, delimiter, config)
      return obj, nextIdx
    end

    local arr = {}
    local colonPos = findUnquotedChar(content, ":")
    if colonPos then
      local afterColon = content:sub(colonPos + 1):match("^%s*(.-)%s*$")
      if afterColon ~= "" then
        local tokens = splitValues(afterColon, headerInfo.delimiter)
        for _, token in ipairs(tokens) do
          table.insert(arr, parseValue(token))
        end
        return arr, startIdx + 1
      end
    end

    if headerInfo.fields then
      return parseTabularRows(lines, startIdx + 1, targetDepth + 1, headerInfo)
    end

    local idx = startIdx + 1
    while idx <= #lines and lines[idx].depth == targetDepth + 1 do
      local item, nextIdx = decodeValue(lines, idx, targetDepth + 1, config, headerInfo.delimiter)
      table.insert(arr, item)
      idx = nextIdx
    end

    return arr, idx
  end

  local colonPos = findUnquotedChar(content, ":")
  if not colonPos then
    return parseValue(content), startIdx + 1
  end

  local value = content:sub(colonPos + 1):match("^%s*(.-)%s*$")
  local obj = {}
  local parsedKey = assertKeyNotNil(parseValue(content:sub(1, colonPos - 1)))

  if value == "" then
    local nextLine = lines[startIdx + 1]
    if nextLine and nextLine.depth == targetDepth + 1 and nextLine.content:sub(1, 2) == "- " then
      obj[parsedKey], startIdx = parseListArray(lines, startIdx + 1, targetDepth + 1, config, delimiter)
    else
      obj[parsedKey], startIdx = decodeValue(lines, startIdx + 1, targetDepth + 1, config, delimiter)
      obj[parsedKey] = obj[parsedKey] or {}
    end
  else
    obj[parsedKey] = parseValue(value)
    startIdx = startIdx + 1
  end

  local nextIdx = collectSiblings(obj, lines, startIdx, targetDepth, delimiter, config)
  return obj, nextIdx
end

---@param text string
---@param options any
---@return any
local function decode(text, options)
  local config = mergeConfig(options)

  if text == "" or text:match("^%s*$") then
    return {}
  end

  local lines = parseLines(text, config)

  if #lines == 0 then
    return {}
  end

  if lines[1].depth == 0 then
    local content = lines[1].content
    local headerInfo = parseHeader(content)

    if headerInfo and not headerInfo.key then
      local result, _ = decodeValue(lines, 1, 0, config, nil)
      return result
    end

    if #lines == 1 and not headerInfo then
      local colonPos = findUnquotedChar(content, ":")
      if not colonPos then
        return parseValue(content)
      end
      local value = content:sub(colonPos + 1):match("^%s*(.-)%s*$")
      if value == "" then
        return { [parseValue(content:sub(1, colonPos - 1))] = {} }
      end
    end
  end

  local obj = {}
  local idx = 1

  while idx <= #lines and lines[idx].depth == 0 do
    local line = lines[idx]
    local headerInfo = parseHeader(line.content)

    if headerInfo and headerInfo.key then
      local arr, nextIdx = decodeValue(lines, idx, 0, config, nil, true)
      obj[headerInfo.key] = arr
      idx = nextIdx
    else
      local colonPos = findUnquotedChar(line.content, ":")

      if not colonPos then
        error("Invalid syntax: " .. line.content)
      else
        local value = line.content:sub(colonPos + 1):match("^%s*(.-)%s*$")
        local parsedKey = assertKeyNotNil(parseValue(line.content:sub(1, colonPos - 1)))

        if value == "" then
          local nextLine = lines[idx + 1]
          if nextLine and nextLine.depth == 1 and nextLine.content:sub(1, 2) == "- " then
            obj[parsedKey], idx = parseListArray(lines, idx + 1, 1, config, ",")
          else
            obj[parsedKey], idx = decodeValue(lines, idx + 1, 1, config, ",")
            obj[parsedKey] = obj[parsedKey] or {}
          end
        else
          obj[parsedKey] = parseValue(value)
          idx = idx + 1
        end
      end
    end
  end

  return obj
end

if _ENV.prelude.toon == nil then
  _ENV.prelude.toon = {}
end

_ENV.prelude.toon.decode = decode

return {
  decode = decode
}
