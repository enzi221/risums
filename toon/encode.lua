local DEFAULT_CONFIG = {
  indent = 2,
  delimiter = ",",
  lengthMarker = false
}

local function isPrimitive(value)
  local t = type(value)
  return t == "string" or t == "number" or t == "boolean" or value == nil
end

local function escapeString(str)
  return str:gsub("\\", "\\\\")
      :gsub("\"", "\\\"")
      :gsub("\n", "\\n")
      :gsub("\r", "\\r")
      :gsub("\t", "\\t")
end

local function isArray(value)
  if type(value) ~= "table" then return false end
  if next(value) == nil then return false end

  local count = 0
  for k, v in pairs(value) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
      return false
    end
    count = count + 1
  end

  for i = 1, count do
    if value[i] == nil then
      return false
    end
  end

  return count > 0
end


local function needsQuoting(str, delimiter)
  if type(str) ~= "string" then return false end
  if str == "" then return true end
  if str:match("^%s") or str:match("%s$") then return true end
  if str == "true" or str == "false" or str == "null" then return true end

  -- Numeric-like
  if str:match("^%-?%d+%.?%d*[eE][%+%-]?%d+$") or
      str:match("^%-?%d+%.%d+$") or
      str:match("^%-?%d+$") or
      str:match("^0%d+$") then
    return true
  end

  if str:find("[:\"[%]{}\\]") or str:find("[\n\r\t]") then return true end
  if str:find(delimiter, 1, true) then return true end
  if str:match("^%-") then return true end

  return false
end

local function encodePrimitive(value, delimiter)
  if value == nil then return "null" end

  local t = type(value)
  if t == "boolean" then return value and "true" or "false" end

  if t == "number" then
    if value ~= value or value == math.huge or value == -math.huge then return "null" end
    if value == math.floor(value) and math.abs(value) >= 1e15 then
      return string.format("%.0f", value)
    elseif math.abs(value) < 1e-5 and value ~= 0 then
      local str = string.format("%.17f", value)
      return str:gsub("(%d)%.(%d-)0+$", "%1.%2"):gsub("(%d)%.$", "%1")
    else
      return string.format("%.16g", value)
    end
  end

  return needsQuoting(value, delimiter) and '"' .. escapeString(value) .. '"' or value
end

local function needsKeyQuoting(key)
  if type(key) ~= "string" then return true end
  return not key:match("^[A-Za-z_][%w_.]*$")
end

local function encodeKey(key)
  return needsKeyQuoting(key) and '"' .. escapeString(key) .. '"' or key
end


local function isAllPrimitives(arr)
  for i = 1, #arr do
    if not isPrimitive(arr[i]) then
      return false
    end
  end
  return true
end

local function isTabularArray(arr)
  if #arr == 0 then return false, nil end

  local firstKeys = {}
  local firstKeyOrder = {}

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

  for i = 2, #arr do
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

    for k in pairs(firstKeys) do
      if not elemKeys[k] then return false, nil end
    end
    for k in pairs(elemKeys) do
      if not firstKeys[k] then return false, nil end
    end
  end

  return true, firstKeyOrder
end

local function encodeValue(value, depth, config, lines, key)
  local indent = string.rep(" ", depth * config.indent)

  if isPrimitive(value) then
    local encoded = encodePrimitive(value, config.delimiter)
    local line = key and (indent .. key .. ": " .. encoded) or (indent .. encoded)
    table.insert(lines, line)
  elseif type(value) == "table" then
    if isArray(value) then
      local len = #value
      local delimSym = (config.delimiter == "," and "" or config.delimiter)
      local lengthPrefix = config.lengthMarker and "#" or ""

      local prefix = key and (indent .. key) or indent

      if isAllPrimitives(value) then
        local values = {}
        for i = 1, len do
          table.insert(values, encodePrimitive(value[i], config.delimiter))
        end
        local header = "[" .. lengthPrefix .. len .. delimSym .. "]:"
        local valuesStr = #values > 0 and " " .. table.concat(values, config.delimiter) or ""
        table.insert(lines, prefix .. header .. valuesStr)
      else
        local isTabular, fieldOrder = isTabularArray(value)

        if isTabular then
          local fieldNames = {}
          for _, f in ipairs(fieldOrder) do
            table.insert(fieldNames, encodeKey(f))
          end
          local fieldsStr = "{" .. table.concat(fieldNames, config.delimiter) .. "}"
          local header = "[" .. lengthPrefix .. len .. delimSym .. "]" .. fieldsStr .. ":"
          table.insert(lines, prefix .. header)

          for i = 1, len do
            local row = value[i]
            local rowValues = {}
            for _, f in ipairs(fieldOrder) do
              table.insert(rowValues, encodePrimitive(row[f], config.delimiter))
            end
            table.insert(lines, indent .. string.rep(" ", config.indent) .. table.concat(rowValues, config.delimiter))
          end
        else
          local header = "[" .. lengthPrefix .. len .. delimSym .. "]:"
          table.insert(lines, prefix .. header)

          for i = 1, len do
            local item = value[i]
            local itemIndent = indent .. string.rep(" ", config.indent)

            if isPrimitive(item) then
              table.insert(lines, itemIndent .. "- " .. encodePrimitive(item, config.delimiter))
            elseif isArray(item) then
              encodeValue(item, depth + 1, config, lines, "- ")
            else
              local objKeys = {}
              for k in pairs(item) do
                table.insert(objKeys, k)
              end

              if #objKeys == 0 then
                table.insert(lines, itemIndent .. "-")
              else
                local firstKey = objKeys[1]
                local firstValue = item[firstKey]

                if isPrimitive(firstValue) then
                  table.insert(lines,
                    itemIndent .. "- " .. encodeKey(firstKey) .. ": " .. encodePrimitive(firstValue, config.delimiter))
                else
                  table.insert(lines, itemIndent .. "- " .. encodeKey(firstKey) .. ":")
                  encodeValue(firstValue, depth + 2, config, lines, nil)
                end

                for j = 2, #objKeys do
                  local k = objKeys[j]
                  encodeValue(item[k], depth + 1, config, lines, encodeKey(k))
                end
              end
            end
          end
        end
      end
    else
      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end

      if key then
        table.insert(lines, indent .. key .. ":")
        for _, k in ipairs(keys) do
          encodeValue(value[k], depth + 1, config, lines, encodeKey(k))
        end
      else
        for _, k in ipairs(keys) do
          encodeValue(value[k], depth, config, lines, encodeKey(k))
        end
      end
    end
  end
end

local function encode(value, options)
  local config = {}
  for k, v in pairs(DEFAULT_CONFIG) do
    config[k] = v
  end
  if options then
    for k, v in pairs(options) do
      config[k] = v
    end
  end

  local delimMap = { tab = "\t", pipe = "|" }
  config.delimiter = delimMap[config.delimiter] or config.delimiter

  config.lengthMarker = not not config.lengthMarker

  if isPrimitive(value) then
    return encodePrimitive(value, config.delimiter)
  end

  if type(value) == "table" and next(value) == nil then
    return ""
  end

  local lines = {}
  encodeValue(value, 0, config, lines, nil)
  return table.concat(lines, "\n")
end

if _ENV.prelude.toon == nil then
  _ENV.prelude.toon = {}
end

_ENV.prelude.toon.encode = encode
