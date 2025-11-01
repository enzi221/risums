local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= 'nil' then return end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
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

function onOutput(triggerId, output)
  setTriggerId(triggerId)

  if not string.find(output, '</lightboard%-stage>') then
    output = output .. '\n</lightboard-stage>'
  end

  local allBlocks = prelude.extractNodes('lightboard-stage', output)
  local body = nil
  if #allBlocks == 1 then
    body = allBlocks[1]
  end

  if not body then
    return ''
  end

  local premise = {}
  local premiseBlocks = prelude.extractBlocks('Premise', body.content, { 'Episode', 'Guidance' })
  if #premiseBlocks == 0 then
    return ''
  end
  premise = prelude.parseBlock(premiseBlocks[1])

  local episodes = {}
  local episodeBlocks = prelude.extractBlocks('Episode', body.content, { 'Guidance' })
  if #episodeBlocks == 0 then
    return ''
  end
  for _, episodeBlock in ipairs(episodeBlocks) do
    table.insert(episodes, json.encode(prelude.parseBlock(episodeBlock)))
  end

  local guidance = {}
  local guidanceBlocks = prelude.extractBlocks('Guidance', body.content)
  if #guidanceBlocks == 0 then
    return ''
  end
  guidance = prelude.parseBlock(guidanceBlocks[1])

  local val = {
    premise = premise,
    episodes = episodes,
    guidance = guidance
  }

  setChatVar(triggerId, 'lightboard-stage-key', triggerId)
  setChatVar(triggerId, 'lightboard-stage-premise', json.encode(premise))
  setChatVar(triggerId, 'lightboard-stage-episodes', json.encode(episodes))
  setChatVar(triggerId, 'lightboard-stage-guidance', json.encode(guidance))

  return '<lightboard-stage key="' .. triggerId .. '">' .. xor(json.encode(val)) .. '</lightboard-stage>'
end

return onOutput
