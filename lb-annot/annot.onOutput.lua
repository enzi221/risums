local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
end

function onOutput(tid, output)
  setTriggerId(tid)

  if not string.find(output, '<lb%-annot') then
    return nil
  end

  if not string.find(output, '</lb%-annot>') then
    output = output .. '\n</lb-annot>'
  end

  local nodes = prelude.queryNodes('lb-annot', output)
  if #nodes == 0 then
    return prelude.removeAllNodes(output, { 'lb-annot' })
  end

  local chats = getFullChat(triggerId)
  local targetIndex = nil

  for i = #chats, 1, -1 do
    local chat = chats[i]
    if prelude.trim(chat.data) ~= '' and chat.role == 'char' then
      local stripped, count = chat.data:gsub('%-%-%-\n%[LBDATA START%].-LBDATA END%]\n%-%-%-', '')

      if count > 0 then
        targetIndex = i - 1 -- Found; Lua 1-based -> JS 0-based
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
    local annots = json.decode(node.content:gsub('\\\'', '\''))

    if #annots > 0 then
      ---@type AnnotsState
      local annotsState = getState(triggerId, 'lb-annot-data') or {}
      local stack = annotsState.stack or {}

      local newList = {}
      for _, item in ipairs(stack) do
        if item.chatIndex < targetIndex then
          table.insert(newList, item)
        end
      end

      local newAnnots = {}
      for _, annot in ipairs(annots) do
        table.insert(newAnnots, {
          desc = annot[4],
          locator = annot[3],
          -- strip italics or bolds
          target = annot[1]:gsub('[%*_]', ''),
          text = annot[2],
        })
      end

      table.insert(newList, {
        annots = newAnnots,
        chatIndex = targetIndex,
      })

      local maxSaves = tonumber(getGlobalVar(triggerId, 'toggle_lb-annot.maxSaves')) or 5
      while #newList > maxSaves do
        table.remove(newList, 1)
      end

      annotsState.stack = newList

      setState(triggerId, 'lb-annot-data', {
        pinned = annotsState.pinned or {},
        stack = newList,
      })
      reloadChat(triggerId, targetIndex)
    end
  end

  return '<lb-annot of="' .. targetIndex .. '" />'
end

return onOutput
