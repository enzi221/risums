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

function onValidate(triggerId, output)
  setTriggerId(triggerId)

  local node = prelude.queryNodes('lb-xnai', output)
  if #node == 0 then
    return
  end

  local success, content = pcall(prelude.toon.decode, node[#node].content)
  if not success then
    error('InvalidOutput: Invalid TOON format. ' .. tostring(content))
  end

  local chats = getFullChat(triggerId)
  local targetIndex = nil

  for i = #chats, 1, -1 do
    local chat = chats[i]
    if prelude.trim(chat.data) ~= '' and chat.role == 'char' then
      local stripped, count = chat.data:gsub('%-%-%-\n%[LBDATA START%].-LBDATA END%]\n%-%-%-', '')

      if count > 0 then
        targetIndex = i -- Unlike onOutput, we use the index within Lua only, so no offset here
        stripped, _ = prelude.trim(stripped)

        if stripped == '' then
          targetIndex = targetIndex - 1 -- Skip this one; LBDATA-only, content located above
        end

        break
      end
    end
  end

  --- @type XNAIData
  local xnaiContent = content
  local errors = {}

  for _, desc in ipairs(xnaiContent.scenes) do
    local locator = desc.locator or ''
    if locator ~= '' then
      local locStart = chats[targetIndex].data:find(prelude.escMatch(locator))

      print('locating', locator, locStart)

      if not locStart then
        table.insert(errors, 'Cannot locate "' .. locator .. '". Fix the locator or remove the entry.')
      end
    end
  end

  if #errors > 0 then
    error('InvalidOutput: One or more targets are invalid. Aggregated errors:\n' .. table.concat(errors, '\n'))
  end
end

return onValidate
