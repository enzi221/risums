local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= 'nil' then
    prelude.import(triggerId, 'toon.decode')
    return
  end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()

  prelude.import(triggerId, 'toon.decode')
end

local function base64Decode(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = string.gsub(data, '[^' .. b .. '=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r, f = '', (b:find(x) - 1)
    for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c = 0
    for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
    return string.char(c)
  end))
end

local function xordecrypt(str)
  -- Decode from base64
  local decoded = base64Decode(str)

  local result = {}
  for i = 1, #decoded do
    local byte = string.byte(decoded, i)
    table.insert(result, string.char(byte ~ 0xFF)) -- XOR with 0xFF
  end

  return table.concat(result)
end

function onValidate(triggerId, output)
  setTriggerId(triggerId)

  local node = prelude.queryNodes('lb-stage', output)
  if #node == 0 then
    return
  end

  local success, content = pcall(prelude.toon.decode, xordecrypt(node[1].content))
  if not success then
    error('InvalidOutput: Invalid TOON format. ' .. tostring(content))
  end

  -- Check for unknown keys (known keys: objective, phase, episodes, divergence, comment, history, foreshadowing)
  local knownKeys = {
    objective = true,
    phase = true,
    episodes = true,
    divergence = true,
    comment = true,
    history = true
  }

  for key, _ in pairs(content) do
    if not knownKeys[key] then
      error('InvalidOutput: Unknown key "' .. key .. '".')
    end
  end
end

return onValidate
