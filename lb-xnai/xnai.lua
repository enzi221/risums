--! Copyright (c) 2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard Annot

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

---@class XNAIDescriptor
---@field camera string
---@field characters string[]
---@field inlay? string
---@field locator? string
---@field scene string

---@class XNAIData
---@field keyvis XNAIDescriptor
---@field scenes XNAIDescriptor[]

---@class XNAIState
---@field pinned XNAIData[]
---@field stack XNAIData

---@param chatAnnots ChatAnnots
---@param data string
---@param fullState AnnotsState
local function renderInline(chatAnnots, data, fullState)
  local annots = chatAnnots.annots
  if not annots or #annots == 0 then
    return data
  end

  local chatIndex = chatAnnots.chatIndex
  local output = data
  local pinned = fullState.pinned or {}

  for _, annot in ipairs(annots) do
    local target = annot.target
    local desc = annot.desc
    local pinnedState = isPinned(pinned, target)

    local text = annot.text ~= '' and annot.text or target
    local locator = annot.locator ~= '' and annot.locator or text
    local locStart, locEnd = output:find(prelude.escMatch(locator))

    if locStart then
      local before = output:sub(1, locStart - 1)
      local located = output:sub(locStart, locEnd)

      local textStart, textEnd = located:find(prelude.escMatch(text))
      if textStart then
        local prefix = located:sub(1, textStart - 1)
        local suffix = located:sub(textEnd + 1)
        local abbr = tostring(h.span['lb-annot-abbr-wrap'] {
          h.button['lb-annot-abbr'] {
            popovertarget = chatIndex .. text:gsub('%s+', '-'),
            type = 'button',
            text,
          },
          h.span['lb-annot-abbr-pop'] {
            id = chatIndex .. text:gsub('%s+', '-'),
            popover = '',
            h.span['lb-annot-abbr-target'] {
              target,
              h.button['lb-annot-abbr-pin-btn'] {
                risu_btn = 'lb-annot-pin/' .. target .. '_' .. desc,
                type = 'button',
                title = pinnedState and '고정 해제' or '고정',
                pinnedState and h.lb_annot_pin { closed = true, pinned = true } or h.lb_annot_pin { closed = true },
              },
            },
            h.span['lb-annot-abbr-desc'] { desc },
          }
        })
        output = before .. prefix .. abbr .. suffix .. output:sub(locEnd + 1)
      end
    end
  end

  return output
end

---@param xnaiData XNAIData
local function renderCollection(xnaiData)
  local id = triggerId .. '-lb-xnai'

  return tostring(h.div['lb-module-root'] {
    data_id = 'lb-xnai',
    h.button['lb-xnai-opener'] {
      popovertarget = id,
      type = 'button',
      -- add text here?
    },
    h.dialog['lb-dialog lb-xnai-dialog'] {
      id = id,
      popover = '',
      -- whatever contents
      h.button['lb-xnai-close'] {
        popovertarget = id,
        type = 'button',
        "닫기",
      }
    },
  })
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

    local out = data
    local nodes = prelude.queryNodes('lb-xnai', out)
    if #nodes > 0 then
      local node = nodes[#nodes]
      local before = out:sub(1, node.rangeStart - 1)
      local after = out:sub(node.rangeEnd + 1)

      ---@type XNAIData
      local xnaiData = prelude.decode(node.content)

      local success, result = pcall(renderCollection, xnaiData)
      if success then
        out = before .. after .. result
      else
        print("[LightBoard] XNAI collection render failed:", tostring(result))
      end

      for _, item in ipairs(xnaiData.scenes) do
        local success, result = pcall(renderInline, item, out, fullState)
        if success then
          return result
        else
          print("[LightBoard] Annot inline render failed:", tostring(result))
        end
        break
      end
    end

    return out
  end
)

onButtonClick = async(function(tid, code)
  setTriggerId(tid)

  local pinPrefix = 'lb%-annot%-pin/'
  local _, pinPrefixEnd = string.find(code, pinPrefix)

  if pinPrefixEnd then
    local body = code:sub(pinPrefixEnd + 1)
    if body == '' then
      return
    end

    -- body: {target}_{desc}
    local sepPos = body:find('_')
    if not sepPos then
      return
    end

    local target = body:sub(1, sepPos - 1)
    local desc = body:sub(sepPos + 1)

    ---@type AnnotsState
    local annotsState = getState(triggerId, 'lb-annot-data') or {}
    local pinned = annotsState.pinned or {}

    local alreadyPinned = false
    local newPinned = {}
    for _, p in ipairs(pinned) do
      if p.target == target then
        alreadyPinned = true
      else
        table.insert(newPinned, p)
      end
    end

    if alreadyPinned then
      annotsState.pinned = newPinned
    else
      table.insert(pinned, { target = target, desc = desc })
      annotsState.pinned = pinned
    end

    setState(triggerId, 'lb-annot-data', {
      pinned = annotsState.pinned,
      stack = annotsState.stack or {},
    })
    return
  end

  local prefix = "lb%-annot%-delete/"
  local _, prefixEnd = string.find(code, prefix)

  if not prefixEnd then
    return
  end

  local body = code:sub(prefixEnd + 1)
  if body == "" then
    return
  end

  -- body: {chatIndex}[_{target}]
  local parts = prelude.split(body, '_')

  if #parts < 1 then
    return
  end

  local chatIndex = tonumber(parts[1])
  local target = parts[2] -- nil if whole chat deletion

  if not chatIndex then
    alertNormal(tid, chatIndex .. '번 채팅을 찾을 수 없습니다.')
    return
  end

  local confirmMsg = (not target or target == '') and (chatIndex .. '번 채팅의 모든 주석을 지우시겠습니까?') or '정말 이 주석을 지우시겠습니까?'
  local confirmed = alertConfirm(tid, confirmMsg):await()
  if not confirmed then
    return
  end

  ---@type AnnotsState
  local annotsState = getState(triggerId, 'lb-annot-data') or {}
  local stack = annotsState.stack or {}

  if not target or target == '' then
    local newList = {}
    for _, item in ipairs(stack) do
      if item.chatIndex ~= chatIndex then
        table.insert(newList, item)
      end
    end

    annotsState.stack = newList
  else
    local newList = {}
    for _, item in ipairs(stack) do
      if item.chatIndex == chatIndex then
        local newAnnots = {}
        for _, annot in ipairs(item.annots) do
          if annot.target ~= target then
            table.insert(newAnnots, annot)
          end
        end
        item.annots = newAnnots
      end

      table.insert(newList, item)
    end

    annotsState.stack = newList
  end

  setState(triggerId, 'lb-annot-data', {
    pinned = annotsState.pinned or {},
    stack = annotsState.stack,
  })
end)
