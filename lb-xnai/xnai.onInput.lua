local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
end

function onInput(tid, input)
  setTriggerId(tid)

  local node = prelude.queryNodes('lb-xnai', input)[1]
  if not node then
    return input
  end

  input = input:sub(1, node.rangeStart - 1) .. input:sub(node.rangeEnd + 1)
  return input
end

return onInput
