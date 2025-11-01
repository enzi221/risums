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

-- Base64 decoding function (helper)
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

-- XOR decryption function
-- Decrypts a base64-encoded XOR-encrypted string back to original text
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

local function main(data)
  if not data or data == "" then
    return ""
  end

  local nodes = prelude.extractNodes('lightboard-stage', data)
  if #nodes == 0 then
    return data
  end

  local node = nodes[1]
  local content = json.decode(xordecrypt(node.content))

  local premise = content.premise
  local episodes = content.episodes
  local guidance = content.guidance

  if not premise or not episodes or not guidance then
    return data
  end

  local nextEpisode_e = nil
  local episodes_es = {}
  for _, episodeRaw in ipairs(episodes) do
    local isNextEpisode = false
    local episode = json.decode(episodeRaw)

    if not nextEpisode_e and episode.Done ~= 'true' then
      isNextEpisode = true
      nextEpisode_e = h.div {
        h.h3 { episode.Title },
        h.p { episode.Content },
      }
    end

    table.insert(episodes_es, h.div {
      h.h3 {
        '[' .. episode.Stage .. '] ',
        episode.Title,
        h.span {
          episode.Done == 'true' and ' (done)' or isNextEpisode and ' (next)' or '',
        }
      },
      h.p {
        episode.Content,
      }
    })
  end

  local id = 'lb-stage-' .. math.random()

  local html = h.div['lb-module-root'] {
    data_id = 'lightboard-stage',
    h.button['lb-stage-entry'] {
      popovertarget = id,
      type = 'button',
      h.span { premise.Title },
      h.span { premise.Title },
    },
    h.dialog['lb-dialog lb-stage-dialog'] {
      id = id,
      popover = '',
      h.h1 {
        premise.Title,
      },
      h.p {
        premise.Content,
      },
      h.div {
        nextEpisode_e,
      },
      h.p {
        guidance.Content,
      },
      h.details {
        episodes_es,
      },
    },
    h.button['lb-reroll'] {
      risu_btn = "lb-interaction__lightboard-stage__Regenerate",
      type = 'button',
      h.lb_reroll_icon { closed = true }
    },
  }

  return data .. tostring(html)
end

listenEdit(
  "editDisplay",
  function(tid, data, meta)
    setTriggerId(tid)

    if meta and meta.index ~= nil then
      local position = meta.index - getChatLength(triggerId)
      if position < -5 then
        return data
      end
    end

    local success, result = pcall(main, data)
    if success then
      return result
    else
      print("[LightBoard] Stage display failed:", tostring(result))
    end
  end
)

onStart = async(function(tid)
  setTriggerId(tid)

  -- Find the nearest chat with <lightboard-stage-x>
  local fullChat = getFullChat(tid)
  local stageChat = nil
  local searchStart = #fullChat

  for i = searchStart, math.max(searchStart - 10, 1), -1 do
    if fullChat[i].role == "char" and string.find(fullChat[i].data, '<lightboard%-stage') then
      stageChat = fullChat[i]
      break
    end
  end

  if not stageChat then
    setChatVar(tid, 'lightboard-stage-key', '')
    setChatVar(tid, 'lightboard-stage-premise', '')
    setChatVar(tid, 'lightboard-stage-episodes', '')
    setChatVar(tid, 'lightboard-stage-guidance', '')
    return
  end

  local currentKey = getChatVar(tid, 'lightboard-stage-key')

  local stageNodes = prelude.extractNodes('lightboard-stage', stageChat.data)
  if #stageNodes == 0 then
    return
  end

  local stageNode = stageNodes[1]
  local extractedKey = stageNode.attributes.key

  if not extractedKey then
    return
  end

  if currentKey == extractedKey then
    return
  end

  -- Keys don't match, need to update variables
  local decrypted = xordecrypt(stageNode.content)
  local data = json.decode(decrypted)

  setChatVar(tid, 'lightboard-stage-key', extractedKey)
  setChatVar(tid, 'lightboard-stage-premise', json.encode(data.premise) or '')
  setChatVar(tid, 'lightboard-stage-episodes', json.encode(data.episodes) or '')
  setChatVar(tid, 'lightboard-stage-guidance', json.encode(data.guidance) or '')
end)
