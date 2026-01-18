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

  local node = prelude.queryNodes('lb-stage', output)
  if #node == 0 then
    return
  end

  local success, content = pcall(prelude.toon.decode, node[1].content)
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
