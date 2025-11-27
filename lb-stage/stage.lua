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

  local nodes = prelude.extractNodes('lb-stage', data)
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
    data_id = 'lb-stage',
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
          risu_btn = "lb-interaction__lb-stage__Regenerate",
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
          h.span {
            ' (' .. phase.stage .. ')'
          }
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
        h.div {
          'Objective: ' .. (objective.content or ''),
        },
        h.div {
          'Completion: ' .. (objective.completion or ''),
        },
        h.div {
          'Divergence: ' .. (content.divergence or ''),
        },
        h.div {
          'Comment: ' .. (comment or ''),
        },
        h.div {
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

listenEdit(
  "editRequest",
  function(tid, data)
    setTriggerId(tid)

    local latestContent = nil
    local foundLatest = false

    -- find the latest <lb-stage>, remove all
    for i = #data, 1, -1 do
      local msg = data[i]
      local content = msg.content

      if not foundLatest then
        local nodes = prelude.extractNodes('lb-stage', content)
        if nodes and #nodes > 0 then
          local node = nodes[#nodes] -- Take the last node in the message
          local success, res = pcall(function()
            return prelude.toon.decode(xordecrypt(node.content))
          end)

          if success and res then
            latestContent = res
            foundLatest = true
          end
        end
      end

      msg.content = string.gsub(content, '<lb%-stage[^>]*>.-</lb%-stage>', '')
    end

    -- Inject formatted state into <lb-stage-reserve>
    local parts = {}
    if latestContent then
      if latestContent.objective then
        table.insert(parts, "#### Objective")
        if latestContent.objective.title then
          table.insert(parts, latestContent.objective.title)
        end
        if latestContent.objective.content then
          table.insert(parts, latestContent.objective.content)
        end
        if latestContent.objective.completion then
          table.insert(parts, "Completion: " .. latestContent.objective.completion)
        end
      end

      if latestContent.phase then
        table.insert(parts, "\n#### Phase")
        local title = latestContent.phase.title or "Unknown"
        local stage = latestContent.phase.stage or "unknown"
        table.insert(parts, title .. " (" .. stage .. ")")
        if latestContent.phase.content then
          table.insert(parts, latestContent.phase.content)
        end
      end

      if latestContent.episodes and #latestContent.episodes > 0 then
        table.insert(parts, "\n#### Episodes")
        for _, ep in ipairs(latestContent.episodes) do
          local stage = ep.stage or "?"
          local title = ep.title or "?"
          local state = ep.state or "?"
          local content = ep.content or ""
          table.insert(parts, string.format("- [%s] %s (%s): %s", stage, title, state, content))
        end
      end

      if latestContent.comment and latestContent.comment ~= "none" and latestContent.comment ~= "" then
        table.insert(parts, "\n#### System Comment")
        table.insert(parts, latestContent.comment)
      end
    else
      table.insert(parts, "(None defined yet)")
    end

    local formattedStr = table.concat(parts, "\n")

    for i = 1, #data do
      local content = data[i].content
      local s, e = string.find(content, '<lb%-stage%-reserve />')
      if s then
        data[i].content = string.sub(content, 1, s - 1) .. formattedStr .. string.sub(content, e + 1)
        break
      end
    end

    return data
  end
)
