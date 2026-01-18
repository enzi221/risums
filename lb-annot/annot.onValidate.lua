local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
end

function onValidate(triggerId, output)
  setTriggerId(triggerId)

  local node = prelude.queryNodes('lb-annot', output)
  if #node == 0 then
    return
  end

  local success, content = pcall(json.decode, node[#node].content:gsub('\\\'', '\''))
  if not success then
    error('InvalidOutput: Invalid JSON format. ' .. tostring(content))
  end

  local errors = {}
  for i, annot in ipairs(content) do
    if annot[1] == '' then
      table.insert(errors, 'Target #' .. i .. ' is missing its target field.')
    end
    if annot[2] == '' then
      table.insert(errors, 'Target #' .. i .. ' is missing its text field.')
    end
    if #annot[2] < #annot[1] then
      table.insert(errors, 'Target #' .. i .. ' has shorter text than its target which is impossible.')
    end
    if #annot[3] ~= '' and #annot[3] < #annot[2] then
      table.insert(errors, 'Target #' .. i .. ' has shorter locator than its text which is impossible.')
    end
    if annot[4] == '' then
      table.insert(errors, 'Target #' .. i .. ' is missing its desc field.')
    end
  end
  if #errors > 0 then
    error('InvalidOutput: Malformed data format. Aggregated errors:\n' .. table.concat(errors, '\n'))
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

  for _, annot in ipairs(content) do
    local text = annot[2] ~= '' and annot[2] or annot[1]

    local locator = annot[3] ~= '' and annot[3] or text[2]
    local locStart, locEnd = chats[targetIndex].data:find(prelude.escMatch(locator))

    print('locating', locator, locStart)

    if not locStart then
      table.insert(errors, 'Cannot locate "' .. locator .. '". Fix the locator or remove the entry.')
    else
      local located = chats[targetIndex].data:sub(locStart, locEnd)
      local textStart = located:find(prelude.escMatch(text))

      print('texting', text, textStart)

      if not textStart then
        table.insert(errors,
          'Cannot find "' .. text .. '" within the locator. Fix the locator or remove the entry.')
      end
    end
  end
  if #errors > 0 then
    error('InvalidOutput: One or more targets are invalid. Aggregated errors:\n' .. table.concat(errors, '\n'))
  end
end

return onValidate
