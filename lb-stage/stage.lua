--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Stage

local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= 'nil' then
    prelude.import(tid, 'toon.decode')
    return
  end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
  prelude.import(tid, 'toon.decode')
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
  local content = prelude.toon.decode(xordecrypt(node.content))

  local objective = content.objective
  local phase = content.phase
  local episodes = content.episodes
  local comment = content.comment == null and '' or content.comment
  local history = content.history == null and '' or content.history

  if not objective or not phase or not episodes then
    return data
  end

  local nextEpisode = nil
  local nextEpisode_e = nil
  local episodes_es = {}
  for _, episode in ipairs(episodes) do
    if not nextEpisode and (episode.state == 'ongoing' or episode.state == 'pending') then
      nextEpisode = episode
      nextEpisode_e = h.div {
        h.h4 { episode.title },
        h.p { episode.content },
      }
    end

    table.insert(episodes_es, h.div {
      h.h4 {
        '[' .. episode.stage .. '] ',
        episode.title,
        h.span {
          ' (' .. episode.state .. ')'
        }
      },
      h.p {
        episode.content,
      }
    })
  end

  local id = 'lb-stage-' .. math.random()

  local playing = phase.title .. (nextEpisode and ' - ' .. nextEpisode.title or '')

  local html = h.div['lb-module-root'] {
    data_id = 'lightboard-stage',
    h.button['lb-stage-entry'] {
      popovertarget = id,
      type = 'button',
      h.span['lb-stage-entry-window'] {
        h.span['lb-stage-entry-roller'] {
          h.span { playing },
          h.span { playing },
        }
      }
    },
    h.dialog['lb-dialog lb-stage-dialog'] {
      id = id,
      popover = '',
      h.div {
        style = 'float: right;',
        h.button['lb-reroll'] {
          risu_btn = "lb-interaction__lightboard-stage__Regenerate",
          type = 'button',
          h.lb_reroll_icon { closed = true }
        },
      },
      h.hgroup {
        h.h1 {
          objective.title,
        },
        h.h2['lb-stage-phase'] {
          phase.title,
        },
        h.p {
          phase.content,
        },
      },
      h.h3 {
        'Ongoing Episode',
      },
      nextEpisode_e,
      h.details {
        h.summary 'All Episodes (Spoilers)',
        episodes_es,
      },
      h.details {
        h.summary 'Debug (Spoilers)',
        h.p {
          'Objective: ' .. (objective.content or ''),
        },
        h.p {
          'Completion: ' .. (objective.completion or ''),
        },
        h.p {
          'Divergence: ' .. (content.divergence or ''),
        },
        h.p {
          'Comment: ' .. (comment or ''),
        },
        h.p {
          'History: ' .. (history or ''),
        }
      }
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

    return data
  end
)

onStart = async(function(tid)
  setTriggerId(tid)

  local currentKey = getChatVar(tid, 'lightboard-stage-key')

  if not currentKey or currentKey == '' or currentKey == 'null' then
    setChatVar(tid, 'lightboard-stage-key', '')
    setChatVar(tid, 'lightboard-stage-raw', '')
    setChatVar(tid, 'lightboard-stage-objective', '')
    setChatVar(tid, 'lightboard-stage-phase', '')
    setChatVar(tid, 'lightboard-stage-episodes', '')
    setChatVar(tid, 'lightboard-stage-comment', '')
    setChatVar(tid, 'lightboard-stage-divergence', '')
    return
  end

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
    setChatVar(tid, 'lightboard-stage-raw', '')
    setChatVar(tid, 'lightboard-stage-objective', '')
    setChatVar(tid, 'lightboard-stage-phase', '')
    setChatVar(tid, 'lightboard-stage-episodes', '')
    setChatVar(tid, 'lightboard-stage-comment', '')
    setChatVar(tid, 'lightboard-stage-divergence', '')

    stopChat(tid)
    alertNormal(tid, "[LightBoard] Stage: 리롤 감지. 스테이지를 업데이트했습니다. 메시지를 다시 전송해주세요.")
    return
  end

  local stageNodes = prelude.extractNodes('lightboard-stage', stageChat.data)
  if #stageNodes == 0 then
    return
  end

  local stageNode = stageNodes[1]
  local extractedKey = stageNode.attributes.key

  if not extractedKey or currentKey == extractedKey then
    return
  end

  -- Keys don't match, need to update variables
  local decrypted = xordecrypt(stageNode.content)

  local data = prelude.toon.decode(decrypted)
  local deepEncodedEpisodes = {}
  for _, episode in ipairs(data.episodes) do
    table.insert(deepEncodedEpisodes, json.encode(episode))
  end

  setChatVar(tid, 'lightboard-stage-key', extractedKey)
  setChatVar(tid, 'lightboard-stage-raw', decrypted)
  setChatVar(tid, 'lightboard-stage-objective', json.encode(data.objective) or '')
  setChatVar(tid, 'lightboard-stage-phase', json.encode(data.phase) or '')
  setChatVar(tid, 'lightboard-stage-episodes', json.encode(deepEncodedEpisodes) or '')
  setChatVar(tid, 'lightboard-stage-comment', data.comment or '')
  setChatVar(tid, 'lightboard-stage-divergence', data.divergence or '')

  stopChat(tid)
  alertNormal(tid, "[LightBoard] Stage: 리롤 감지. 스테이지를 업데이트했습니다. 메시지를 다시 전송해주세요.")
end)
