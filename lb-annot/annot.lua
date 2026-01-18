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

---@class AnnotData
---@field desc string
---@field locator string
---@field text string
---@field target string

---@class ChatAnnots
---@field annots AnnotData[]
---@field chatIndex number

---@class PinnedAnnotData
---@field chatIndex number
---@field desc string
---@field target string

---@param pinned PinnedAnnotData[]
---@param target string
local function isPinned(pinned, target)
  for _, p in ipairs(pinned) do
    if p.target == target then
      return true
    end
  end
  return false
end

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

---@class AnnotsState
---@field pinned PinnedAnnotData[]
---@field stack ChatAnnots[]

---@param chatAnnotsMaybe ChatAnnots?
---@param fullState AnnotsState
local function renderCollection(chatAnnotsMaybe, fullState)
  local id = triggerId .. '-lb-annot'

  local chatAnnots = chatAnnotsMaybe or {}
  local annots = chatAnnots.annots or {}
  local pinned = fullState.pinned or {}

  local annot_es = #annots > 0 and {} or { h.div['lb-annot-collection-empty'] { '여기 달린 주석이 없어요' } }
  for _, annot in ipairs(annots) do
    local pinnedState = isPinned(pinned, annot.target)
    table.insert(annot_es, h.li['lb-annot-item'] {
      h.span['lb-annot-target'] {
        annot.target,
        h.button['lb-annot-pin-btn'] {
          popovertarget = id,
          risu_btn = 'lb-annot-pin/' .. annot.target .. '_' .. annot.desc,
          type = 'button',
          title = pinnedState and '고정 해제' or '고정',
          pinnedState and h.lb_annot_pin { closed = true, pinned = true } or h.lb_annot_pin { closed = true },
        },
        h.button['lb-annot-delete-btn'] {
          popovertarget = id,
          risu_btn = 'lb-annot-delete/' .. chatAnnots.chatIndex .. '_' .. annot.target,
          type = 'button',
          title = '주석 삭제',
          h.lb_trash_icon { closed = true },
        },
      },
      h.span['lb-annot-desc'] { annot.desc }
    })
  end

  local target_es = #annots > 0 and {} or { h.span['lb-annot-opener-item'] { '지난 주석 보기' } }
  for _, annot in ipairs(annots) do
    table.insert(target_es, h.span['lb-annot-opener-item'] { annot.target })
  end

  local stack_es = {}
  for i = #fullState.stack, 1, -1 do
    local chatData = fullState.stack[i]
    if chatData.annots and #chatData.annots > 0 then
      local chatAnnot_es = {}
      for _, annot in ipairs(chatData.annots) do
        table.insert(chatAnnot_es, h.div['lb-annot-saved-item'] {
          h.span['lb-annot-saved-target'] {
            annot.target,
          },
          h.span['lb-annot-saved-desc'] { annot.desc }
        })
      end

      table.insert(stack_es, h.div['lb-annot-hist-group'] {
        h.div['lb-annot-hist-header'] {
          '#' .. chatData.chatIndex,
          h.button['lb-annot-hist-delete-btn'] {
            popovertarget = id,
            risu_btn = 'lb-annot-delete/' .. chatData.chatIndex,
            type = 'button',
            title = '전체 삭제',
            h.lb_trash_icon { closed = true },
          },
        },
        h.div['lb-annot-hist-items'](chatAnnot_es),
      })
    end
  end

  if #stack_es == 0 then
    stack_es = { h.div['lb-annot-collection-empty'] { '저장된 주석이 없어요' } }
  end

  local pinned_es = {}
  for _, p in ipairs(pinned) do
    table.insert(pinned_es, h.div['lb-annot-saved-item'] {
      h.span['lb-annot-saved-target'] { p.target },
      h.span['lb-annot-saved-desc'] { p.desc },
      h.button['lb-annot-unpin-btn'] {
        popovertarget = id,
        risu_btn = 'lb-annot-pin/' .. p.target .. '_' .. p.desc,
        type = 'button',
        title = '고정 해제',
        h.lb_annot_pin { closed = true, pinned = true },
      },
    })
  end

  local pinned_section = #pinned > 0 and h.div['lb-annot-pinned'] {
    h.div['lb-annot-pinned-header'] { '고정된 주석' },
    h.div['lb-annot-pinned-list'](pinned_es),
  } or nil

  return tostring(h.div['lb-module-root'] {
    data_id = 'lb-annot',
    h.button['lb-annot-opener'] {
      popovertarget = id,
      type = 'button',
      target_es,
    },
    h.dialog['lb-dialog lb-annot-dialog'] {
      id = id,
      popover = '',
      h.header['lb-annot-header'] {
        h.span '주석 목록',
        h.button['lb-reroll'] {
          popovertarget = id,
          risu_btn = 'lb-reroll__lb-annot',
          type = 'button',
          h.lb_reroll_icon { closed = true }
        },
      },
      h.ul['lb-annot-list'](annot_es),
      h.details['lb-annot-history'] {
        h.summary { '지난 기록' },
        pinned_section,
        h.div['lb-annot-history-content'](stack_es),
      },
      h.button['lb-annot-close'] {
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

    ---@type AnnotsState
    local fullState = getState(triggerId, 'lb-annot-data') or {}

    local out = data
    local nodes = prelude.queryNodes('lb-annot', out)
    if #nodes > 0 then
      local node = nodes[#nodes]
      local before = out:sub(1, node.rangeStart - 1)
      local after = out:sub(node.rangeEnd + 1)

      ---@type ChatAnnots?
      local annots = nil
      for _, chatAnnots in ipairs(fullState.stack) do
        if chatAnnots.chatIndex == (tonumber(node.attributes.of) or meta.index) then
          annots = chatAnnots
          break
        end
      end

      local success, result = pcall(renderCollection, annots, fullState)
      if success then
        out = before .. after .. result
      else
        print("[LightBoard] Annot collection render failed:", tostring(result))
      end
    end

    for _, item in ipairs(fullState.stack) do
      if item.chatIndex == meta.index then
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
