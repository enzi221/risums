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

-- Base64 encoding function (helper)
local function base64Encode(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r, b = '', x:byte()
    for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c = 0
    for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
    return b:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function xor(str)
  local result = {}
  for i = 1, #str do
    local byte = string.byte(str, i)
    table.insert(result, byte ~ 0xFF) -- XOR with 0xFF
  end

  -- Convert to base64
  local bytes = string.char(table.unpack(result))
  return base64Encode(bytes)
end

local function main(output)
  if not string.find(output, '</lightboard%-stage>') then
    output = output .. '\n</lightboard-stage>'
  end

  local allBlocks = prelude.extractNodes('lightboard-stage', output)
  local body = nil
  if #allBlocks == 1 then
    body = allBlocks[1]
  end

  if not body then
    print('[LightBoard] No <lightboard-stage> block found')
    return ''
  end

  local data = prelude.toon.decode(body.content)
  if not data or not data.objective or not data.phase or not data.episodes then
    print('[LightBoard] Stage content invalid')
    return '<lb-lazy identifier="lightboard-stage"></lb-lazy>'
  end

  local deepEncodedEpisodes = {}
  for _, episode in ipairs(data.episodes) do
    table.insert(deepEncodedEpisodes, json.encode(episode))
  end

  setChatVar(triggerId, 'lightboard-stage-key', triggerId)
  setChatVar(triggerId, 'lightboard-stage-raw', body.content)
  setChatVar(triggerId, 'lightboard-stage-objective', json.encode(data.objective))
  setChatVar(triggerId, 'lightboard-stage-phase', json.encode(data.phase))
  setChatVar(triggerId, 'lightboard-stage-episodes', json.encode(deepEncodedEpisodes))
  setChatVar(triggerId, 'lightboard-stage-divergence', data.divergence)
  setChatVar(triggerId, 'lightboard-stage-comment', data.comment)

  return '<lightboard-stage key="' .. triggerId .. '">' .. xor(body.content) .. '</lightboard-stage>'
end

function onOutput(triggerId, output)
  setTriggerId(triggerId)

  local success, result = pcall(main, output)
  if success then
    return result
  else
    print("[LightBoard] Stage output failed:", tostring(result))
    return output
  end
end

return onOutput
