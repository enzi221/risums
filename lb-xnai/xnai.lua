--! Copyright (c) 2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard XNAI

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
---@field keyvis? XNAIDescriptor
---@field scenes? XNAIDescriptor[]

---@class XNAIStackItem
---@field chatIndex number
---@field xnai XNAIData

---@class XNAIPinnedItem
---@field chatIndex number
---@field sceneIndex number
---@field label string
---@field desc XNAIDescriptor

---@class XNAIState
---@field pinned XNAIPinnedItem[]
---@field stack XNAIStackItem[]

local function buildRawPrompt(desc)
  local lead = {}
  if desc.scene and desc.scene ~= '' then
    table.insert(lead, desc.scene)
  end
  if desc.camera and desc.camera ~= '' then
    table.insert(lead, desc.camera)
  end

  local leadText = #lead > 0 and table.concat(lead, ', ') or ''

  local chars = {}
  if desc.characters then
    for _, character in ipairs(desc.characters) do
      if character and character ~= '' then
        table.insert(chars, character)
      end
    end
  end

  local parts = {}
  if leadText ~= '' then
    table.insert(parts, leadText)
  end
  for _, character in ipairs(chars) do
    table.insert(parts, character)
  end

  return table.concat(parts, ' | ')
end

local function buildPresetPrompt(desc)
  local lead = {}
  if desc.camera and desc.camera ~= '' then
    table.insert(lead, desc.camera)
  end
  if desc.scene and desc.scene ~= '' then
    table.insert(lead, desc.scene)
  end

  local leadText = #lead > 0 and table.concat(lead, ', ') or ''

  local chars = {}
  if desc.characters then
    for _, character in ipairs(desc.characters) do
      if character and character ~= '' then
        table.insert(chars, character)
      end
    end
  end

  local preset = getGlobalVar(triggerId, 'toggle_lb-xnai.preset')
  if not preset or preset == '' or preset == 'null' then
    preset = '1'
  end

  local presetBook = prelude.getPriorityLoreBook(triggerId, '프리셋 ' .. tostring(preset))
  if not presetBook or not presetBook.content or presetBook.content == '' then
    presetBook = prelude.getPriorityLoreBook(triggerId, '프리셋 1')
  end

  if not presetBook or not presetBook.content or presetBook.content == '' then
    alertError(triggerId, 'XNAI 프리셋 로어북을 찾을 수 없습니다.')
    return '', ''
  end

  local content = prelude.trim(presetBook.content)
  local positive = content:match('%[Positive%]%s*([%s%S]-)%s*%[Negative%]')
  local negative = content:match('%[Negative%]%s*([%s%S]-)%s*$')

  positive = positive and prelude.trim(positive) or ''
  negative = negative and prelude.trim(negative) or ''

  if positive ~= '' then
    if positive:find('{prompt}', 1, true) then
      positive = positive:gsub('{prompt}', leadText)
    elseif leadText ~= '' then
      positive = table.concat({ leadText, positive }, ', ')
    end
  else
    positive = leadText
  end

  local positiveNote = getGlobalVar(triggerId, 'toggle_lb-xnai.positive') or ''
  if positiveNote ~= '' and positiveNote ~= null then
    positive = table.concat({ positive, positiveNote }, ', ')
  end
  local negativeNote = getGlobalVar(triggerId, 'toggle_lb-xnai.negative') or ''
  if negativeNote ~= '' and negativeNote ~= null then
    negative = table.concat({ negative, negativeNote }, ', ')
  end

  if #chars > 0 then
    local charText = table.concat(chars, ' | ')
    if positive ~= '' then
      positive = positive .. ' | ' .. charText
    else
      positive = charText
    end
  end

  return positive, negative
end

local function getPinnedIndex(pinned, chatIndex, sceneIndex)
  for i, item in ipairs(pinned) do
    if item.chatIndex == chatIndex and item.sceneIndex == sceneIndex then
      return i
    end
  end
  return nil
end

local function renderDescriptorInline(desc, chatIndex, sceneIndex, pinned, isKeyvis)
  local pinnedState = getPinnedIndex(pinned or {}, chatIndex, sceneIndex) ~= nil

  local btn = h.button['lb-xnai-gen-btn'] {
    risu_btn = 'lb-xnai-gen/' .. chatIndex .. '_' .. sceneIndex,
    title = '재생성',
    type = 'button',
    h.lb_xnai_play_icon { closed = true },
  }

  local pinBtn = h.button['lb-xnai-pin-btn'] {
    risu_btn = 'lb-xnai-pin/' .. chatIndex .. '_' .. sceneIndex,
    title = pinnedState and '고정 해제' or '고정',
    type = 'button',
    pinnedState and h.lb_pin_icon { closed = true, pinned = true } or h.lb_pin_icon { closed = true },
  }

  local containerClass = isKeyvis and 'lb-xnai-inlay-kv' or 'lb-xnai-inlay'

  if not desc.inlay or desc.inlay == '' then
    local placeholderText = isKeyvis and '키 비주얼 생성' or ('씬 #' .. sceneIndex .. ' 생성')
    local placeholder = h.button['lb-xnai-placeholder'] {
      risu_btn = 'lb-xnai-gen/' .. chatIndex .. '_' .. sceneIndex,
      type = 'button',
      '✦ ' .. placeholderText,
    }
    return tostring(h.div['lb-xnai-placeholder-wrapper'] { placeholder })
  end

  if isKeyvis then
    local wrapperClass = 'lb-xnai-inlay-kv-wrapper'
    return tostring(h.div[wrapperClass] { h.div[containerClass] { btn, pinBtn, desc.inlay } })
  end

  local actionsClass = 'lb-xnai-inlay-actions'
  local actions = h.div[actionsClass] { btn, pinBtn }

  local popId = 'lb-xnai-pop-' .. chatIndex .. '-' .. sceneIndex

  local fullsizePop = h.dialog['lb-xnai-fullsize-pop'] {
    id = popId,
    popover = '',
    desc.inlay,
    h.div['lb-xnai-fullsize-actions'] { btn, pinBtn },
  }

  local inlayImg = h.button {
    popovertarget = popId,
    type = 'button',
    desc.inlay,
  }

  return tostring(h.div[containerClass] { actions, inlayImg, fullsizePop })
end

---@param xnaiData XNAIData
---@param data string
---@param chatIndex number
local function renderInline(xnaiData, data, chatIndex, pinned)
  local output = data
  local scenes = xnaiData.scenes or {}

  local keyvis = xnaiData.keyvis
  if keyvis then
    local keyvisInlay = renderDescriptorInline(keyvis, chatIndex, 0, pinned, true)
    local xnaiPos = getGlobalVar(triggerId, 'toggle_lb-xnai.kv.position') or '0'
    local lbPos = getGlobalVar(triggerId, 'toggle_lightboard.position') or '0'

    -- xnai 아래(1) + lb 아래 = ---\n[LBDATA START] 앞에
    -- xnai 위(0) + lb 위 = [LBDATA END]\n--- 뒤에
    -- 나머지(분리 포함) = 그냥 붙임
    if xnaiPos == '1' and lbPos == '0' then
      local markerStart = '%-%-%-\n%[LBDATA START%]'
      local startPos = output:find(markerStart)
      if startPos then
        output = output:sub(1, startPos - 1) .. keyvisInlay .. '\n\n' .. output:sub(startPos)
      else
        output = output .. '\n\n' .. keyvisInlay
      end
    elseif xnaiPos == '0' and lbPos == '1' then
      local markerEnd = '%[LBDATA END%]\n%-%-%-'
      local _, endPos = output:find(markerEnd)
      if endPos then
        output = output:sub(1, endPos) .. '\n\n' .. keyvisInlay .. output:sub(endPos + 1)
      else
        output = keyvisInlay .. '\n\n' .. output
      end
    elseif xnaiPos == '0' then
      output = keyvisInlay .. '\n\n' .. output
    else
      output = output .. '\n\n' .. keyvisInlay
    end
  end

  for sceneIndex, desc in ipairs(scenes) do
    local locator = desc.locator or ''
    if locator ~= '' then
      local locStart, locEnd = output:find(prelude.escMatch(locator))
      if locStart then
        local lineEnd = output:find('\n', locEnd + 1)
        local insertPos = lineEnd or #output
        local before = output:sub(1, insertPos)
        local after = output:sub(insertPos + 1)
        local inlay = renderDescriptorInline(desc, chatIndex, sceneIndex, pinned, false)
        output = before .. '\n' .. inlay .. '\n' .. after
      end
    end
  end

  return output
end

---@param stackItemMaybe XNAIStackItem?
---@param fullState XNAIState
local function renderCollection(stackItemMaybe, fullState)
  local id = triggerId .. '-lb-xnai'

  local stackItem = stackItemMaybe or {}
  local current = stackItem.xnai or {}
  local pinned = fullState.pinned or {}
  local stack = fullState.stack or {}

  local function renderDescriptorItem(desc, label, chatIndex, sceneIndex)
    local isDone = desc.inlay and desc.inlay ~= ''
    local status = isDone and '완료' or '대기'
    local prompt = buildRawPrompt(desc)
    local pinnedState = getPinnedIndex(pinned, chatIndex, sceneIndex) ~= nil
    local inlay = isDone and desc.inlay or nil
    local inlayWrapped = nil
    if inlay then
      inlayWrapped = h.div['lb-xnai-collection-inlay'] { inlay }
    end

    local statusEl = isDone
        and h.span['lb-xnai-item-status'] { data_done = '', status }
        or h.span['lb-xnai-item-status'] { status }

    return h.details['lb-xnai-item'] {
      name = 'lb-xnai-item-' .. chatIndex,
      h.summary['lb-xnai-item-head'] {
        h.span['lb-xnai-item-title'] {
          label,
          h.button['lb-xnai-gen-btn'] {
            popovertarget = id,
            risu_btn = 'lb-xnai-gen/' .. chatIndex .. '_' .. sceneIndex,
            title = '재생성',
            type = 'button',
            h.lb_xnai_play_icon { closed = true },
          },
        },
        statusEl,
        h.button['lb-xnai-pin-btn'] {
          risu_btn = 'lb-xnai-pin/' .. chatIndex .. '_' .. sceneIndex,
          title = pinnedState and '고정 해제' or '고정',
          type = 'button',
          pinnedState and h.lb_pin_icon { closed = true, pinned = true } or h.lb_pin_icon { closed = true },
        },
        h.button['lb-xnai-delete-btn'] {
          popovertarget = id,
          risu_btn = 'lb-xnai-delete/' .. chatIndex .. '_' .. sceneIndex,
          title = '삭제',
          type = 'button',
          h.lb_trash_icon { closed = true },
        },
      },
      h.div['lb-xnai-item-body'] {
        h.pre['lb-xnai-prompt'] { prompt },
        inlayWrapped,
      },
    }
  end

  local current_es = {}
  if current.keyvis then
    table.insert(current_es, renderDescriptorItem(current.keyvis, '키 비주얼', stackItem.chatIndex or 0, 0))
  end

  for i, desc in ipairs(current.scenes or {}) do
    table.insert(current_es, renderDescriptorItem(desc, '씬 #' .. i, stackItem.chatIndex or 0, i))
  end

  if #current_es == 0 then
    current_es = { h.div['lb-xnai-collection-empty'] { '표시할 씬이 없어요' } }
  end

  local function renderHistoryScene(desc, label, chatIndex, sceneIndex)
    local pinnedState = getPinnedIndex(pinned, chatIndex, sceneIndex) ~= nil
    local inlayWrapped = nil
    if desc.inlay and desc.inlay ~= '' then
      inlayWrapped = h.div['lb-xnai-collection-inlay'] { desc.inlay }
    end

    return h.div['lb-xnai-hist-scene'] {
      h.div['lb-xnai-hist-scene-head'] {
        h.span['lb-xnai-item-title'] { label },
        h.button['lb-xnai-pin-btn'] {
          risu_btn = 'lb-xnai-pin/' .. chatIndex .. '_' .. sceneIndex,
          type = 'button',
          pinnedState and h.lb_pin_icon { closed = true, pinned = true } or h.lb_pin_icon { closed = true },
        },
        h.button['lb-xnai-delete-btn'] {
          popovertarget = id,
          risu_btn = 'lb-xnai-delete/' .. chatIndex .. '_' .. sceneIndex,
          type = 'button',
          h.lb_trash_icon { closed = true },
        },
      },
      inlayWrapped,
    }
  end

  local stack_es = {}
  for i = #stack, 1, -1 do
    local item = stack[i]
    local hist_scenes = {}
    if item.xnai and item.xnai.keyvis then
      table.insert(hist_scenes, renderHistoryScene(item.xnai.keyvis, '키 비주얼', item.chatIndex, 0))
    end
    for sceneIndex, desc in ipairs(item.xnai and item.xnai.scenes or {}) do
      table.insert(hist_scenes, renderHistoryScene(desc, '씬 #' .. sceneIndex, item.chatIndex, sceneIndex))
    end

    if #hist_scenes == 0 then
      hist_scenes = { h.div['lb-xnai-collection-empty'] { '표시할 씬이 없어요' } }
    end

    table.insert(stack_es, h.details['lb-xnai-hist-entry'] {
      open = true,
      h.summary['lb-xnai-hist-summary'] {
        h.span['lb-xnai-hist-index'] { '#' .. item.chatIndex },
        h.button['lb-xnai-delete-btn'] {
          popovertarget = id,
          risu_btn = 'lb-xnai-delete/' .. item.chatIndex,
          type = 'button',
          h.lb_trash_icon { closed = true },
        },
      },
      h.div['lb-xnai-hist-scenes'](hist_scenes),
    })
  end

  if #stack_es == 0 then
    stack_es = { h.div['lb-xnai-collection-empty'] { '저장된 기록이 없어요' } }
  end

  local pinned_es = {}
  for _, p in ipairs(pinned) do
    local prompt = buildRawPrompt(p.desc)
    local inlay = (p.desc.inlay and p.desc.inlay ~= '') and p.desc.inlay or nil
    local inlayWrapped = nil
    if inlay then
      inlayWrapped = h.div['lb-xnai-collection-inlay'] { inlay }
    end
    table.insert(pinned_es, h.details['lb-xnai-pinned-item'] {
      h.summary['lb-xnai-pinned-head'] {
        h.span['lb-xnai-pinned-title'] { p.label },
        h.button['lb-xnai-pin-btn'] {
          risu_btn = 'lb-xnai-pin/' .. p.chatIndex .. '_' .. p.sceneIndex,
          type = 'button',
          h.lb_pin_icon { closed = true, pinned = true },
        },
      },
      h.div['lb-xnai-pinned-body'] {
        h.pre['lb-xnai-prompt'] { prompt },
        inlayWrapped,
      },
    })
  end

  local pinned_section = #pinned > 0 and h.div['lb-xnai-pinned'] {
    h.div['lb-xnai-pinned-header'] { '고정' },
    h.div['lb-xnai-pinned-list'](pinned_es),
  } or nil

  return tostring(h.div['lb-module-root'] {
    data_id = 'lb-xnai',
    h.button['lb-xnai-opener'] {
      popovertarget = id,
      type = 'button',
      '삽화 모아보기',
    },
    h.dialog['lb-dialog lb-xnai-dialog'] {
      id = id,
      popover = '',
      h.header['lb-xnai-header'] {
        h.span '삽화 모아보기',
        stackItem.chatIndex and h.button['lb-xnai-genall-btn'] {
          popovertarget = id,
          risu_btn = 'lb-xnai-genall/' .. stackItem.chatIndex,
          type = 'button',
          '전체 생성',
        } or nil,
        h.button['lb-reroll'] {
          popovertarget = id,
          risu_btn = 'lb-reroll__lb-xnai',
          type = 'button',
          h.lb_reroll_icon { closed = true },
        },
      },
      h.ul['lb-xnai-list'](current_es),
      h.details['lb-xnai-history'] {
        open = true,
        h.summary['lb-xnai-history-summary'] { '지난 기록' },
        pinned_section,
        h.div['lb-xnai-history-content'](stack_es),
      },
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

    ---@type XNAIState
    local fullState = getState(triggerId, 'lb-xnai-data') or {}

    local out = data
    local nodes = prelude.queryNodes('lb-xnai', out)
    if #nodes > 0 then
      local node = nodes[#nodes]
      local before = out:sub(1, node.rangeStart - 1)
      local after = out:sub(node.rangeEnd + 1)

      ---@type XNAIStackItem?
      local stackItem = nil
      for _, item in ipairs(fullState.stack or {}) do
        if item.chatIndex == (tonumber(node.attributes.of) or meta.index) then
          stackItem = item
          break
        end
      end

      local success, result = pcall(renderCollection, stackItem, fullState)
      if success then
        out = before .. after .. result
      else
        print("[LightBoard] XNAI collection render failed:", tostring(result))
      end
    end

    for _, item in ipairs(fullState.stack or {}) do
      if item.chatIndex == meta.index then
        local success, result = pcall(renderInline, item.xnai, out, item.chatIndex, fullState.pinned or {})
        if success then
          return result
        else
          print("[LightBoard] XNAI inline render failed:", tostring(result))
        end
        break
      end
    end

    return out
  end
)

onButtonClick = async(function(tid, code)
  setTriggerId(tid)

  local pinPrefix = 'lb%-xnai%-pin/'
  local _, pinPrefixEnd = string.find(code, pinPrefix)

  if pinPrefixEnd then
    local body = code:sub(pinPrefixEnd + 1)
    if body == '' then
      return
    end

    local parts = prelude.split(body, '_')
    if #parts < 2 then
      return
    end

    local chatIndex = tonumber(parts[1])
    local sceneIndex = tonumber(parts[2])

    if not chatIndex or not sceneIndex then
      return
    end

    ---@type XNAIState
    local xnaiState = getState(triggerId, 'lb-xnai-data') or {}
    local stack = xnaiState.stack or {}
    local pinned = xnaiState.pinned or {}

    local pinnedIndex = getPinnedIndex(pinned, chatIndex, sceneIndex)
    if pinnedIndex then
      table.remove(pinned, pinnedIndex)
    else
      local targetItem = nil
      for _, item in ipairs(stack) do
        if item.chatIndex == chatIndex then
          targetItem = item
          break
        end
      end

      if not targetItem or not targetItem.xnai then
        return
      end

      local desc = nil
      local label = nil
      if sceneIndex == 0 then
        desc = targetItem.xnai.keyvis
        label = '#' .. chatIndex .. '-KV'
      else
        desc = targetItem.xnai.scenes and targetItem.xnai.scenes[sceneIndex]
        label = '#' .. chatIndex .. '-씬' .. sceneIndex
      end

      if not desc then
        return
      end

      table.insert(pinned, {
        chatIndex = chatIndex,
        sceneIndex = sceneIndex,
        label = label,
        desc = desc,
      })
    end

    setState(triggerId, 'lb-xnai-data', {
      pinned = pinned,
      stack = stack,
    })
    reloadChat(triggerId, chatIndex)
    reloadChat(triggerId, chatIndex + 1)
    return
  end

  local deletePrefix = 'lb%-xnai%-delete/'
  local _, deletePrefixEnd = string.find(code, deletePrefix)

  if deletePrefixEnd then
    local body = code:sub(deletePrefixEnd + 1)
    if body == '' then
      return
    end

    local parts = prelude.split(body, '_')
    if #parts < 1 then
      return
    end

    local chatIndex = tonumber(parts[1])
    local sceneIndex = parts[2] and tonumber(parts[2]) or nil

    if not chatIndex then
      return
    end

    local confirmMsg = sceneIndex and '정말 이 씬을 지우시겠습니까?' or (chatIndex .. '번 채팅의 모든 씬을 지우시겠습니까?')
    local confirmed = alertConfirm(tid, confirmMsg):await()
    if not confirmed then
      return
    end

    ---@type XNAIState
    local xnaiState = getState(triggerId, 'lb-xnai-data') or {}
    local stack = xnaiState.stack or {}

    if sceneIndex then
      for _, item in ipairs(stack) do
        if item.chatIndex == chatIndex and item.xnai then
          if sceneIndex == 0 then
            item.xnai.keyvis = nil
          elseif item.xnai.scenes then
            table.remove(item.xnai.scenes, sceneIndex)
          end
          break
        end
      end
    else
      local newStack = {}
      for _, item in ipairs(stack) do
        if item.chatIndex ~= chatIndex then
          table.insert(newStack, item)
        end
      end
      xnaiState.stack = newStack
    end

    setState(triggerId, 'lb-xnai-data', {
      pinned = xnaiState.pinned or {},
      stack = xnaiState.stack or {},
    })
    reloadChat(triggerId, chatIndex)
    reloadChat(triggerId, chatIndex + 1)
    return
  end

  local genPrefix = 'lb%-xnai%-gen/'
  local _, genPrefixEnd = string.find(code, genPrefix)

  if not genPrefixEnd then
    local genAllPrefix = 'lb%-xnai%-genall/'
    local _, genAllPrefixEnd = string.find(code, genAllPrefix)

    if not genAllPrefixEnd then
      return
    end

    local body = code:sub(genAllPrefixEnd + 1)
    if body == '' then
      return
    end

    local chatIndex = tonumber(body)
    if not chatIndex then
      return
    end

    addChat(tid, 'user',
      '<lb-rerolling><div class="lb-pending lb-rerolling"><span class="lb-pending-note">이미지 생성 중, 채팅을 보내거나 다른 작업을 하지 마세요...</span></div></lb-rerolling>')

    ---@type XNAIState
    local xnaiState = getState(triggerId, 'lb-xnai-data') or {}
    local stack = xnaiState.stack or {}

    local targetItem = nil
    for _, item in ipairs(stack) do
      if item.chatIndex == chatIndex then
        targetItem = item
        break
      end
    end

    if not targetItem or not targetItem.xnai then
      removeChat(tid, -1)
      return
    end

    local descriptors = {}
    if targetItem.xnai.keyvis then
      table.insert(descriptors, { index = 0, desc = targetItem.xnai.keyvis })
    end
    for i, desc in ipairs(targetItem.xnai.scenes or {}) do
      table.insert(descriptors, { index = i, desc = desc })
    end

    for _, item in ipairs(descriptors) do
      local desc = item.desc
      local prompt, negative = buildPresetPrompt(desc)
      if prompt ~= '' then
        local inlay = generateImage(tid, prompt, negative or ''):await()
        if inlay and inlay ~= '' then
          desc.inlay = inlay
        end
      end
    end

    setState(triggerId, 'lb-xnai-data', {
      pinned = xnaiState.pinned or {},
      stack = stack,
    })

    reloadChat(triggerId, chatIndex)
    reloadChat(triggerId, chatIndex + 1)
    removeChat(tid, -1)
    return
  end

  local body = code:sub(genPrefixEnd + 1)
  if body == '' then
    return
  end

  -- body: {chatIndex}_{sceneIndex}
  local parts = prelude.split(body, '_')
  if #parts < 2 then
    return
  end

  local chatIndex = tonumber(parts[1])
  local sceneIndex = tonumber(parts[2])

  if not chatIndex or not sceneIndex then
    return
  end

  ---@type XNAIState
  local xnaiState = getState(triggerId, 'lb-xnai-data') or {}
  local stack = xnaiState.stack or {}

  ---@type XNAIStackItem?
  local targetItem = nil
  for _, item in ipairs(stack) do
    if item.chatIndex == chatIndex then
      targetItem = item
      break
    end
  end

  if not targetItem or not targetItem.xnai or not targetItem.xnai.scenes then
    return
  end

  local desc = nil
  if sceneIndex == 0 then
    desc = targetItem.xnai.keyvis
  else
    desc = targetItem.xnai.scenes[sceneIndex]
  end
  if not desc then
    return
  end

  local prompt, negative = buildPresetPrompt(desc)
  if prompt == '' then
    alertNormal(tid, '프롬프트가 비어 있어요.')
    return
  end

  addChat(tid, 'user',
    '<lb-rerolling><div class="lb-pending lb-rerolling"><span class="lb-pending-note">이미지 생성 중, 채팅을 보내거나 다른 작업을 하지 마세요...</span></div></lb-rerolling>')

  local inlay = generateImage(tid, prompt, negative or ''):await()
  if inlay and inlay ~= '' then
    desc.inlay = inlay
    setState(triggerId, 'lb-xnai-data', {
      pinned = xnaiState.pinned or {},
      stack = stack,
    })

    reloadChat(triggerId, chatIndex)
    reloadChat(triggerId, chatIndex + 1)
  end
  removeChat(tid, -1)
end)
