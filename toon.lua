-- TOON (Text Object Oriented Notation) Encoder
-- Specification: https://github.com/alattalatta/toon

local toon = {}

-- Default configuration
local DEFAULT_CONFIG = {
  indent = 2,
  delimiter = ",",
  lengthMarker = false
}

-- Utility: Check if value is array-like
local function isArray(value)
  if type(value) ~= "table" then return false end
  local count = 0
  for k, v in pairs(value) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
      return false
    end
    count = count + 1
  end
  return count > 0 or next(value) == nil
end

-- Utility: Get array length
local function arrayLength(arr)
  local len = 0
  for k, v in pairs(arr) do
    if type(k) == "number" and k > len then
      len = k
    end
  end
  return len
end

-- Utility: Check if value is primitive
local function isPrimitive(value)
  local t = type(value)
  return t == "string" or t == "number" or t == "boolean" or value == nil
end

-- Utility: Escape string per Section 7.1
local function escapeString(str)
  return str:gsub("\\", "\\\\")
      :gsub("\"", "\\\"")
      :gsub("\n", "\\n")
      :gsub("\r", "\\r")
      :gsub("\t", "\\t")
end

-- Utility: Check if string needs quoting per Section 7.2
local function needsQuoting(str, delimiter)
  if type(str) ~= "string" then return false end

  -- Empty string
  if str == "" then return true end

  -- Leading or trailing whitespace
  if str:match("^%s") or str:match("%s$") then return true end

  -- Reserved words
  if str == "true" or str == "false" or str == "null" then return true end

  -- Numeric-like
  if str:match("^%-?%d+%.?%d*[eE][%+%-]?%d+$") or
      str:match("^%-?%d+%.%d+$") or
      str:match("^%-?%d+$") or
      str:match("^0%d+$") then
    return true
  end

  -- Contains structural characters
  if str:find("[:\\\"\\[\\]{}]", 1, false) then return true end

  -- Contains control characters
  if str:find("[\n\r\t]") then return true end

  -- Contains delimiter
  if delimiter == "," and str:find(",", 1, true) then return true end
  if delimiter == "\t" and str:find("\t", 1, true) then return true end
  if delimiter == "|" and str:find("|", 1, true) then return true end

  -- Starts with hyphen
  if str:match("^%-") then return true end

  return false
end

-- Utility: Encode primitive value
local function encodePrimitive(value, delimiter)
  if value == nil then
    return "null"
  elseif type(value) == "boolean" then
    return value and "true" or "false"
  elseif type(value) == "number" then
    -- Normalize -0 to 0
    if value == 0 then value = 0 end

    -- Handle special numbers
    if value ~= value then return "null" end                            -- NaN
    if value == math.huge or value == -math.huge then return "null" end -- Infinity

    -- Format without scientific notation
    local str = string.format("%.17g", value)
    -- Remove trailing zeros after decimal point
    str = str:gsub("(%d)%.(%d-)0+$", "%1.%2"):gsub("%.$", "")
    return str
  elseif type(value) == "string" then
    if needsQuoting(value, delimiter) then
      return '"' .. escapeString(value) .. '"'
    else
      return value
    end
  end

  return "null"
end

-- Utility: Check if key needs quoting per Section 7.3
local function needsKeyQuoting(key)
  if type(key) ~= "string" then return true end
  return not key:match("^[A-Za-z_][%w_.]*$")
end

-- Utility: Encode key
local function encodeKey(key)
  if needsKeyQuoting(key) then
    return '"' .. escapeString(key) .. '"'
  else
    return key
  end
end

-- Utility: Get delimiter symbol for header
local function getDelimiterSymbol(delimiter)
  if delimiter == "\t" then return "\t" end
  if delimiter == "|" then return "|" end
  return "" -- comma is default, no symbol needed
end

-- Utility: Check if array is all primitives
local function isAllPrimitives(arr)
  for i = 1, arrayLength(arr) do
    if not isPrimitive(arr[i]) then
      return false
    end
  end
  return true
end

-- Utility: Check if array is uniform objects for tabular form
local function isTabularArray(arr)
  if #arr == 0 then return false, nil end

  local firstKeys = {}
  local firstKeyOrder = {}

  -- Check first element
  if type(arr[1]) ~= "table" or isArray(arr[1]) then
    return false, nil
  end

  for k, v in pairs(arr[1]) do
    if not isPrimitive(v) then
      return false, nil
    end
    firstKeys[k] = true
    table.insert(firstKeyOrder, k)
  end

  -- Check remaining elements
  for i = 2, arrayLength(arr) do
    local elem = arr[i]
    if type(elem) ~= "table" or isArray(elem) then
      return false, nil
    end

    local elemKeys = {}
    for k, v in pairs(elem) do
      if not isPrimitive(v) then
        return false, nil
      end
      elemKeys[k] = true
    end

    -- Check same keys
    for k in pairs(firstKeys) do
      if not elemKeys[k] then return false, nil end
    end
    for k in pairs(elemKeys) do
      if not firstKeys[k] then return false, nil end
    end
  end

  return true, firstKeyOrder
end

-- Main encoding function
local function encodeValue(value, depth, config, lines, currentDelimiter, key)
  local indent = string.rep(" ", depth * config.indent)
  local activeDelimiter = currentDelimiter or config.delimiter

  if value == nil or type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
    -- Primitive value
    local encoded = encodePrimitive(value, activeDelimiter)
    if key then
      table.insert(lines, indent .. key .. ": " .. encoded)
    else
      table.insert(lines, indent .. encoded)
    end
  elseif type(value) == "table" then
    if isArray(value) then
      local len = arrayLength(value)
      local delimSym = getDelimiterSymbol(activeDelimiter)
      local lengthPrefix = config.lengthMarker and "#" or ""

      if isAllPrimitives(value) then
        -- Inline primitive array
        local values = {}
        for i = 1, len do
          table.insert(values, encodePrimitive(value[i], activeDelimiter))
        end
        local header = "[" .. lengthPrefix .. len .. delimSym .. "]:"
        if key then
          if #values > 0 then
            table.insert(lines, indent .. key .. header .. " " .. table.concat(values, activeDelimiter))
          else
            table.insert(lines, indent .. key .. header)
          end
        else
          if #values > 0 then
            table.insert(lines, indent .. header .. " " .. table.concat(values, activeDelimiter))
          else
            table.insert(lines, indent .. header)
          end
        end
      else
        -- Check for tabular form
        local isTabular, fieldOrder = isTabularArray(value)

        if isTabular then
          -- Tabular array
          local fieldNames = {}
          for _, f in ipairs(fieldOrder) do
            table.insert(fieldNames, encodeKey(f))
          end
          local fieldsStr = "{" .. table.concat(fieldNames, activeDelimiter) .. "}"
          local header = "[" .. lengthPrefix .. len .. delimSym .. "]" .. fieldsStr .. ":"

          if key then
            table.insert(lines, indent .. key .. header)
          else
            table.insert(lines, indent .. header)
          end

          -- Rows
          for i = 1, len do
            local row = value[i]
            local rowValues = {}
            for _, f in ipairs(fieldOrder) do
              table.insert(rowValues, encodePrimitive(row[f], activeDelimiter))
            end
            table.insert(lines, indent .. string.rep(" ", config.indent) .. table.concat(rowValues, activeDelimiter))
          end
        else
          -- Mixed/non-uniform array - expanded list
          local header = "[" .. lengthPrefix .. len .. delimSym .. "]:"
          if key then
            table.insert(lines, indent .. key .. header)
          else
            table.insert(lines, indent .. header)
          end

          -- List items
          for i = 1, len do
            local item = value[i]
            local itemIndent = indent .. string.rep(" ", config.indent)

            if isPrimitive(item) then
              table.insert(lines, itemIndent .. "- " .. encodePrimitive(item, activeDelimiter))
            elseif isArray(item) then
              -- Nested array as list item
              encodeValue(item, depth + 1, config, lines, activeDelimiter, "-")
            else
              -- Object as list item
              local objKeys = {}
              for k in pairs(item) do
                table.insert(objKeys, k)
              end

              if #objKeys == 0 then
                table.insert(lines, itemIndent .. "-")
              else
                -- First field on hyphen line
                local firstKey = objKeys[1]
                local firstValue = item[firstKey]

                if isPrimitive(firstValue) then
                  table.insert(lines,
                    itemIndent .. "- " .. encodeKey(firstKey) .. ": " .. encodePrimitive(firstValue, activeDelimiter))
                else
                  table.insert(lines, itemIndent .. "- " .. encodeKey(firstKey) .. ":")
                  encodeValue(firstValue, depth + 2, config, lines, activeDelimiter, nil)
                end

                -- Remaining fields
                for j = 2, #objKeys do
                  local k = objKeys[j]
                  encodeValue(item[k], depth + 1, config, lines, activeDelimiter, encodeKey(k))
                end
              end
            end
          end
        end
      end
    else
      -- Object
      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end

      if key then
        if #keys == 0 then
          table.insert(lines, indent .. key .. ":")
        else
          table.insert(lines, indent .. key .. ":")
          for _, k in ipairs(keys) do
            encodeValue(value[k], depth + 1, config, lines, activeDelimiter, encodeKey(k))
          end
        end
      else
        -- Root object
        for _, k in ipairs(keys) do
          encodeValue(value[k], depth, config, lines, activeDelimiter, encodeKey(k))
        end
      end
    end
  end
end

-- Public encode function
function toon.encode(value, options)
  local config = {}
  for k, v in pairs(DEFAULT_CONFIG) do
    config[k] = v
  end
  if options then
    for k, v in pairs(options) do
      config[k] = v
    end
  end

  -- Normalize delimiter
  if config.delimiter == "tab" then config.delimiter = "\t" end
  if config.delimiter == "pipe" then config.delimiter = "|" end

  local lines = {}

  -- Handle root forms
  if isPrimitive(value) then
    table.insert(lines, encodePrimitive(value, config.delimiter))
  elseif isArray(value) then
    encodeValue(value, 0, config, lines, config.delimiter, nil)
  else
    -- Root object
    if next(value) == nil then
      -- Empty object at root = empty document
      return ""
    end
    encodeValue(value, 0, config, lines, config.delimiter, nil)
  end

  return table.concat(lines, "\n")
end

return toon
