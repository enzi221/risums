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

function onOutput(triggerId, output)
  setTriggerId(triggerId)

  if not string.find(output, "</lb%-mini>") then
    output = output .. '\n</lb-mini>'
  end

  return prelude.removeAllNodes(output, { 'lb-mini', 'lb-process' })
end

return onOutput
