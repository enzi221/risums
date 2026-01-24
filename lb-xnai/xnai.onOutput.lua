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

function onOutput(tid, output)
  setTriggerId(tid)

  if not string.find(output, '<lb%-xnai') then
    return nil
  end

  if not string.find(output, '</lb%-xnai>') then
    output = output .. '\n</lb-xnai>'
  end

  local nodes = prelude.queryNodes('lb-xnai', output)
  if #nodes == 0 then
    return prelude.removeAllNodes(output, { 'lb-xnai' })
  end

  local chats = getFullChat(triggerId)
  local targetIndex = nil

  for i = #chats, 1, -1 do
    local chat = chats[i]
    if prelude.trim(chat.data) ~= '' and chat.role == 'char' then
      local stripped, count = chat.data:gsub('%-%-%-\n%[LBDATA START%].-LBDATA END%]\n%-%-%-', '')

      if count > 0 then
        targetIndex = i - 1 -- Lua 1-based -> JS 0-based
        stripped, _ = prelude.trim(stripped)

        if stripped == '' then
          targetIndex = targetIndex - 1 -- Skip this one; LBDATA-only, content located above
        end

        break
      end
    end
  end

  if targetIndex then
    local node = nodes[#nodes]
    local success, xnaiData = pcall(prelude.toon.decode, node.content)

    if success then
      ---@type XNAIState
      local xnaiState = getState(triggerId, 'lb-xnai-data') or {}
      local stack = xnaiState.stack or {}

      local newList = {}
      for _, item in ipairs(stack) do
        if item.chatIndex < targetIndex then
          table.insert(newList, item)
        end
      end

      table.insert(newList, {
        xnai = xnaiData,
        chatIndex = targetIndex,
      })

      local maxSaves = tonumber(getGlobalVar(triggerId, 'toggle_lb-xnai.maxSaves')) or 5
      while #newList > maxSaves do
        table.remove(newList, 1)
      end

      xnaiState.stack = newList

      setState(triggerId, 'lb-xnai-data', {
        pinned = xnaiState.pinned or {},
        stack = newList,
      })
      reloadChat(triggerId, targetIndex)
    end
  end

  return '<lb-xnai of="' .. targetIndex .. '">\n' .. nodes[#nodes].content .. '\n</lb-xnai>'
end

return onOutput
