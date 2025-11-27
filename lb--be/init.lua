--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Backend

---@diagnostic disable: lowercase-global

local manifest = require('./manifest')
local prompt = require('./prompts')

local VALIDATION_ERROR_PREFIX = "InvalidOutput:"

local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= "nil" then return end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
end

--- Inserts content before [LBDATA END] marker, or appends if not found.
--- @param text string
--- @param newContent string
--- @return string
local function fallbackInsert(text, newContent)
  local footerPattern = "%[LBDATA END%]"
  local footerStart = text:find(footerPattern)

  if footerStart then
    local lineStart = footerStart
    while lineStart > 1 and text:sub(lineStart - 1, lineStart - 1) ~= '\n' do
      lineStart = lineStart - 1
    end

    return text:sub(1, lineStart - 1) .. '\n' .. newContent .. '\n' .. text:sub(lineStart)
  else
    return text .. '\n' .. newContent
  end
end

--- Inserts content at position.
--- @param text string
--- @param position number
--- @param newContent string
--- @return string
local function insertAtPosition(text, position, newContent)
  return text:sub(1, position - 1) .. newContent .. '\n' .. text:sub(position)
end

--- Strips a node block and returns its position.
--- @param text string
--- @param tagName string
--- @param attrs table<string, string>?
--- @return string modifiedText, number? removedPosition
local function removeNode(text, tagName, attrs)
  if not text then return '', nil end

  local nodes = prelude.queryNodes(tagName, text)
  if #nodes == 0 then return text, nil end

  local targetNode = nil
  if attrs then
    for _, node in ipairs(nodes) do
      local matchAttrs = true
      for k, v in pairs(attrs) do
        if node.attributes[k] ~= v then
          matchAttrs = false
          break
        end
      end
      if matchAttrs then
        targetNode = node
        break
      end
    end
  else
    targetNode = nodes[1]
  end

  if not targetNode then return text, nil end

  local prefix = text:sub(1, targetNode.rangeStart - 1):gsub("\n+$", "")
  local suffix = text:sub(targetNode.rangeEnd + 1):gsub("^\n+", "")

  -- Return position adjusted for the new text (after prefix + newline)
  return prefix .. '\n' .. suffix, #prefix + 2
end

--- Finds the last chat index with `char` role within a range.
--- @param fullChat Chat[]
--- @param startOffset number (e.g., -1, -2, ...)
--- @param range number (how many logs to search back)
--- @return number? index, Chat? chat
local function findLastCharChat(fullChat, startOffset, range)
  local searchStart = #fullChat + startOffset
  local searchEnd = math.max(searchStart - (range or 5), 1)

  for i = searchStart, searchEnd, -1 do
    if fullChat[i] and fullChat[i].role == 'char' then
      return i, fullChat[i]
    end
  end
  return nil, nil
end

--- @param man Manifest
--- @param prom Chat[]
--- @param modeOverride '1'|'2'?
local function runLLM(man, prom, modeOverride)
  local mode = modeOverride or man.mode

  if mode == '1' then
    return LLM(triggerId, prom)
  else
    return axLLM(triggerId, prom)
  end
end

--- @param man Manifest
--- @param response LLMResult
--- @return string?
local function processLLMResult(man, response)
  if response.success then
    local cleanOutput = response.result:gsub("```[^\n]*\n?", "")
    cleanOutput = removeNode(cleanOutput, "Thoughts")
    cleanOutput = removeNode(cleanOutput, "lb-process")

    if (man.onOutput) then
      local success, modifiedOutput = pcall(man.onOutput, triggerId, cleanOutput)
      if success and modifiedOutput and modifiedOutput ~= '' then
        cleanOutput = modifiedOutput
      else
        print("[LightBoard Backend] Failed processing (onOutput) for " ..
          man.identifier .. ": " .. tostring(modifiedOutput))

        local reason = success and 'nil 반환' or tostring(modifiedOutput)
        error('출력 처리 실패(onOutput). ' .. reason)
      end
    end

    return cleanOutput
  else
    print("[LightBoard Backend] Failed to get LLM response for " .. man.identifier .. ":\n" .. response.result)
    error('LLM 요청 실패. ' .. response.result)
  end
end

--- @class PipelineOptions
--- @field type 'generation'|'interaction'
--- @field extras string?
--- @field lazy boolean? Manifest laziness or reroll/interaction eagerness

--- Pipeline for prompt creation, LLM execution, and result processing.
--- @param man Manifest
--- @param fullChat Chat[]
--- @param options PipelineOptions
--- @return string?
local function runPipeline(man, fullChat, options)
  local modeType = options.type

  if modeType ~= 'interaction' and options.lazy then
    return '\n<lb-lazy id="' .. man.identifier .. '" />'
  end

  local promptSuccess, promptResult = pcall(prompt.make, triggerId, man, fullChat, modeType, options.extras)
  if not promptSuccess then
    print("[LightBoard] Failed to create prompt for " .. man.identifier .. ": " .. tostring(promptResult))
    return '\n<lb-lazy id="' .. man.identifier .. '" />'
  end
  local prom = promptResult
  print('[LightBoard Backend][VERBOSE] Prompt created.')

  local maxRetries = tonumber(getGlobalVar(triggerId, "toggle_lightboard.maxRetries")) or 0
  local retryMode = getGlobalVar(triggerId, 'toggle_lightboard.retryMode') or '0'

  local attempts = 0

  while true do
    print('[LightBoard Backend][VERBOSE] Prompt submitted. Try #' .. attempts)

    --- @type '1'|'2'|nil
    --- @diagnostic disable-next-line: assign-type-mismatch
    local modeOverride = attempts > 0 and retryMode ~= '0' and retryMode or nil

    local response = runLLM(man, prom, modeOverride)
    print('[LightBoard Backend][VERBOSE] Received response.')

    local processSuccess, result = pcall(processLLMResult, man, response)
    if not processSuccess then
      error('응답을 처리하지 못했습니다. ' .. tostring(result))
    end
    print('[LightBoard Backend][VERBOSE] Response processed.')

    -- critical failure, instant fallback
    if modeType == 'generation' and (not result or result == '' or result == null) then
      error('모델 응답이 비어있거나 null입니다. 검열됐을 수 있습니다.')
    end

    -- validation from FE
    local valid = true
    local validationError = nil

    if man.onValidate and result then
      print('[LightBoard Backend][VERBOSE] Response validating.')

      local success, err = pcall(man.onValidate, triggerId, result)
      if not success then
        local cleanErr = tostring(err):gsub("^.-:%d+: ", "")
        if cleanErr:find("^" .. VALIDATION_ERROR_PREFIX) then
          -- only if the error is a validation error
          valid = false
          validationError = cleanErr:sub(#VALIDATION_ERROR_PREFIX + 1):match("^%s*(.-)%s*$")
        else
          -- assume success otherwise
          print("[LightBoard] Validation script error in " .. man.identifier .. ": " .. tostring(err))
        end
      end
    end

    if valid or attempts >= maxRetries then
      print('[LightBoard Backend][VERBOSE] Validation complete.')

      if not valid then
        print('[LightBoard] Validation failed for ' ..
          man.identifier .. ' but max retries reached: ' .. tostring(validationError))
      end
      return result
    end

    attempts = attempts + 1
    print("[LightBoard] Validation failed for " ..
      man.identifier .. ". Retrying (" .. attempts .. "/" .. maxRetries .. "): " .. tostring(validationError))

    table.insert(prom, {
      content = result,
      role = 'char'
    })

    local thoughtsFlag = getGlobalVar(triggerId, 'toggle_lightboard.thoughts') or '0'
    local printInstruction =
    'Only print the corrected structured data without apologies, explanations, or any preambles.'
    if thoughtsFlag == '0' then
      printInstruction =
      'Only print the corrected structured data without `<lb-process>` block, apologies, explanations, or any preambles.'
    end

    local retryInstruction = string.format([[<system>
Validation error!

Your previous output did not adhere to the required format, or contained invalid data.
Error message: %s

Please fix your last output into correct structure as previously instructed, while keeping the data intact.

%s
</system>]],
      validationError, printInstruction)

    table.insert(prom, {
      role = 'user',
      content = retryInstruction
    })
  end
end

--- @type fun(man: Manifest, chatContext: Chat[], options: PipelineOptions): Promise<string?>
local runPipelineAsync = async(runPipeline)

local main = async(function()
  local mode = getGlobalVar(triggerId, "toggle_lightboard.active") or "0"
  if mode == "0" then
    return
  end

  local fullChat = getFullChat(triggerId)

  --- @diagnostic disable-next-line: param-type-mismatch
  local manifests = manifest.list(triggerId)
  if #manifests == 0 then
    print("[LightBoard] No active manifests.")
    return
  end

  local allProcessedResults = {}
  local maxConcurrent = math.min(5, math.max(1, tonumber(getGlobalVar(triggerId, "toggle_lightboard.concurrent")) or 1))

  for i = 1, #manifests, maxConcurrent do
    --- @type Promise<string>[]
    local currentChunkPromises = {}
    local chunkEndIndex = math.min(i + maxConcurrent - 1, #manifests)

    for j = i, chunkEndIndex do
      local man = manifests[j]
      table.insert(currentChunkPromises, runPipelineAsync(man, fullChat, {
        type = 'generation',
        lazy = man.lazy
      }))
    end

    --- @type string[]
    local chunkResults = Promise.all(currentChunkPromises):await()
    if chunkResults then
      for _, chunkResult in ipairs(chunkResults) do
        if type(chunkResult) == "string" and chunkResult ~= "" then
          table.insert(allProcessedResults, chunkResult)
        end
      end
    end
  end

  if #allProcessedResults > 0 then
    local position = getGlobalVar(triggerId, 'toggle_lightboard.position') or '0'

    -- Get latest full chat again in case of other scripts modified it
    local fullChatNewest = getFullChat(triggerId)
    local lastCharChatIdx = findLastCharChat(fullChatNewest, 0, 5)
    local lastCharChat = lastCharChatIdx and fullChatNewest[lastCharChatIdx].data or ''

    local header = '---\n[LBDATA START]'
    local contents = table.concat(allProcessedResults, '\n\n')
    local footer = '\n\n[LBDATA END]\n---'

    local assembled = header .. contents .. footer
    local finalMessage = position == '0'
        and lastCharChat .. '\n\n' .. assembled
        or assembled .. '\n\n' .. lastCharChat

    setChat(triggerId, lastCharChatIdx ~= nil and (lastCharChatIdx - 1) or -1, finalMessage)
  else
    print("[LightBoard] All manifests processed. No new content to add.")
  end
end)

onOutput = async(function(tid)
  setTriggerId(tid)

  if getGlobalVar(tid, "toggle_lightboard.active") == "0" then
    return
  end

  local success, result = pcall(function()
    local mainPromise = main()
    return mainPromise:await()
  end)

  if not success then
    print("[LightBoard Backend] Backend Error: " .. tostring(result))
    alertError(tid, "[LightBoard] 백엔드 오류. 개발자에게 문의해주세요.\n" .. tostring(result))
  end
end)

---@param identifier string module identifier
---@param blockID string? for rerolling specific block
local function reroll(identifier, blockID)
  local mode = getGlobalVar(triggerId, "toggle_lightboard.active") or "O"
  if mode == "0" then
    error('리롤 전에 백엔드를 활성화해주세요.')
    return
  end

  local man = manifest.get(triggerId, identifier)
  if not man then
    error('이 모듈을 찾을 수 없습니다. 프론트엔드의 모드 토글이 설정돼있나요?')
    return
  end

  local fullChat = getFullChat(triggerId)
  local idx, targetChat = findLastCharChat(fullChat, 0, 5)

  if not idx or not targetChat then
    error('리롤 불가 - 마지막 5개 채팅 중 캐릭터 채팅이 없습니다.')
    return
  end

  local originalContent = targetChat.data
  local withoutLazy, lazyPos = removeNode(originalContent, 'lb-lazy', { id = identifier })
  local withoutSelf, prevPos = removeNode(withoutLazy, identifier, blockID and { id = blockID } or nil)

  setChat(triggerId, -1, withoutLazy)
  -- TODO: Move out of reroll
  addChat(triggerId, 'user',
    '<lb-rerolling><div class="lb-pending lb-rerolling"><span class="lb-pending-note">' ..
    identifier .. ' 재생성 중, 채팅을 보내거나 다른 모듈을 재생성하지 마세요...</span></div></lb-rerolling>')

  -- Use the later position if both exist (adjust pos1 if lazy node came first)
  local targetPosition = nil
  if prevPos and lazyPos then
    if prevPos < lazyPos then
      -- Second removal was before first, adjust first position
      local removed = originalContent:sub(prevPos, prevPos + (withoutSelf:len() - withoutLazy:len()))
      targetPosition = lazyPos - removed:len()
    else
      targetPosition = lazyPos
    end
  elseif lazyPos then
    targetPosition = lazyPos
  elseif prevPos then
    targetPosition = prevPos
  end

  local cleanOutput = withoutSelf
  local targetChatIdx = idx - 1 --[[offset for the addChat]]

  -- force rerender
  setChat(triggerId, targetChatIdx, cleanOutput)

  if man.rerollBehavior == "remove-prev" then
    targetChat.data = cleanOutput
  end

  local contextSlice = { table.unpack(fullChat, 1, idx) }

  local success, result = pcall(function()
    return runPipelineAsync(man, contextSlice, { type = 'generation', lazy = false }):await()
  end)

  if not success or not result then
    setChat(triggerId, targetChatIdx, originalContent)
    alertError(triggerId, '[LightBoard] 리롤 실패. ' .. identifier .. ' 개발자에게 문의하세요.\n' .. tostring(result))
    return
  end

  local finalChat
  if targetPosition then
    finalChat = insertAtPosition(withoutSelf, targetPosition, result)
  else
    finalChat = fallbackInsert(withoutSelf, result)
  end

  setChat(triggerId, targetChatIdx,
    man.onMutation and man.onMutation(triggerId, 'reroll', finalChat) or finalChat)
end

--- @class InteractionMod
--- @field action string
--- @field blockID string?
--- @field immediate boolean
--- @field preserve boolean

--- @param action string
--- @return InteractionMod
local function parseInteractionModifiers(action)
  local blockID = nil
  local cleanAction = action
  local immediate = false
  local preserve = false

  local hashPos = action:find("#", 1, true)
  if hashPos then
    local modifiers = action:sub(1, hashPos - 1)
    cleanAction = action:sub(hashPos + 1)

    local modifierParts = prelude.split(modifiers, ";")
    for _, part in ipairs(modifierParts) do
      local trimmed = prelude.trim(part)
      if trimmed == "preserve" then
        preserve = true
      elseif trimmed == "immediate" then
        immediate = true
      elseif trimmed:match("^id=") then
        blockID = trimmed:match("^id=(.+)$")
      end
    end
  end

  return {
    action = cleanAction,
    blockID = blockID,
    preserve = preserve,
    immediate = immediate,
  }
end

---@param fullChat Chat[]
---@param identifier string
---@param action string
---@param direction string
local function interact(fullChat, identifier, action, direction)
  local mode = getGlobalVar(triggerId, "toggle_lightboard.active") or "O"
  if mode == "0" then
    error('리롤 전에 백엔드를 활성화해주세요.')
    return
  end

  local man = manifest.get(triggerId, identifier)
  if not man then
    error('이 모듈을 찾을 수 없습니다. 프론트엔드의 모드 토글이 설정돼있나요?')
    return
  end

  -- #fullChat = direction, #fullChat-1 = identifier+action, #fullChat-2 = last char chat to modify)
  local idx, targetChat = findLastCharChat(fullChat, -1, 5)

  if not idx or not targetChat then
    error('상호작용 불가 - 마지막 5개 채팅 중 캐릭터 채팅이 없습니다.')
    return
  end

  local originalContent = targetChat.data
  local modifiers = parseInteractionModifiers(action)

  local interactionGuideline = prelude.getPriorityLoreBook(triggerId, man.identifier .. ".lb.interaction")
  if not interactionGuideline or interactionGuideline.content == "" then
    error(identifier .. '에 상호작용 지침이 없습니다. 개발자에게 문의하세요.')
  end

  local extraPrompt = string.format([[# Interaction Mode

Note: User has requested interaction with last data block (<%s>). DISREGARD "NO REPEAT" DIRECTIVE. Keep the data intact.

User direction:
```
%s
```

Action: `%s`

%s]], man.identifier, direction, modifiers.action, interactionGuideline.content)

  local contextSlice = { table.unpack(fullChat, 1, idx) }
  local success, result = pcall(function()
    return runPipelineAsync(man, contextSlice, {
      type = 'interaction',
      extras = extraPrompt
    }):await()
  end)

  -- Lua to JS index offset
  local jsIndex = idx - 1

  if not success then
    setChat(triggerId, jsIndex, originalContent)
    alertError(triggerId, "[LightBoard] 상호작용 실패. " .. identifier .. " 개발자에게 문의하세요.\n" .. tostring(result))
    return
  end

  if not result or result == '' or result == null then
    setChat(triggerId, jsIndex, originalContent)
    alertError(triggerId, "[LightBoard] 상호작용 불가. 모델 응답이 비어있거나 null입니다. 검열됐을 수 있습니다.")
    return
  end

  local finalChat

  if modifiers.preserve then
    -- Find last matching node and insert after it
    local existingNodes = prelude.queryNodes(identifier, originalContent)
    local targetNode = nil

    if modifiers.blockID and #existingNodes > 0 then
      for _, node in ipairs(existingNodes) do
        if node.attributes.id == modifiers.blockID then
          targetNode = node
          break
        end
      end
    elseif #existingNodes > 0 then
      targetNode = existingNodes[#existingNodes]
    end

    if targetNode then
      finalChat = originalContent:sub(1, targetNode.rangeEnd) ..
          '\n' .. result .. originalContent:sub(targetNode.rangeEnd + 1)
    else
      finalChat = fallbackInsert(originalContent, result)
    end
  else
    -- Remove node and insert at its position
    local baseContent, targetPosition = removeNode(originalContent, identifier,
      modifiers.blockID and { id = modifiers.blockID } or nil)

    if targetPosition then
      finalChat = insertAtPosition(baseContent, targetPosition, result)
    else
      finalChat = fallbackInsert(baseContent, result)
    end
  end

  if man.onMutation then
    finalChat = man.onMutation(triggerId, 'interaction', finalChat)
  end

  setChat(triggerId, jsIndex, finalChat)
end

onButtonClick = async(function(tid, code)
  setTriggerId(tid)

  local prefix = "lb%-reroll__"
  local _, rerollPrefixEnd = string.find(code, prefix)

  if rerollPrefixEnd then
    local fullIdentifier = code:sub(rerollPrefixEnd + 1)
    if fullIdentifier == "" then
      return
    end

    local hashPos = fullIdentifier:find("#", 1, true)
    local identifier, blockID
    if hashPos then
      identifier = fullIdentifier:sub(1, hashPos - 1)
      blockID = fullIdentifier:sub(hashPos + 1)
      if blockID == "" then
        blockID = nil
      end
    else
      identifier = fullIdentifier
      blockID = nil
    end

    local success, result = pcall(reroll, identifier, blockID)
    if not success then
      alertError(tid, "[LightBoard] 리롤 실패 (" .. identifier .. ").\n" .. tostring(result))
      return
    end

    removeChat(tid, -1)
    return
  end

  prefix = "lb%-interaction__"
  local _, interactionPrefixEnd = string.find(code, prefix)

  if interactionPrefixEnd then
    local body = code:sub(interactionPrefixEnd + 1)
    if body == "" then
      return
    end

    local firstSeparator = body:find("__", 1, true)
    if not firstSeparator then
      return
    end

    local identifier = body:sub(1, firstSeparator - 1)
    local action = body:sub(firstSeparator + 2)

    if identifier == "" or action == "" then
      return
    end

    local mode = getGlobalVar(tid, "toggle_lightboard.active") or "0"
    if mode == "0" then
      alertNormal(tid, '[LightBoard] 상호작용 전에 백엔드를 활성화해주세요.')
      return
    end

    local modifiers = parseInteractionModifiers(action)

    print('[LightBoard Backend][VERBOSE] Interaction ' .. action .. ' of ' .. identifier .. ' initiated.')

    if modifiers.immediate then
      addChat(tid, 'user',
        '<lb-rerolling><div class="lb-pending lb-rerolling"><span class="lb-pending-note">' ..
        identifier .. ' 상호작용 중, 채팅을 보내거나 다른 작업을 하지 마세요...</span></div></lb-rerolling>')

      local fullChat = getFullChat(tid)
      -- #fullChat = pending message, #fullChat-1 = last char chat to modify
      local success, result = pcall(interact, fullChat, identifier, action, "", -2)
      if not success then
        alertError(tid, "[LightBoard] 상호작용 실패 (" .. identifier .. ").\n" .. tostring(result))
        return
      end

      removeChat(tid, -1)
    else
      addChat(tid, 'user',
        '<lb-interaction-identifier>' ..
        identifier .. '</lb-interaction-identifier>\n<lb-interaction-action>' .. action .. '</lb-interaction-action>')
    end
  end
end)

--- Extracts interaction identifier and action from a chat message.
--- @param chatData string
--- @return string?, string?
local function extractInteraction(chatData)
  local identifierNode = prelude.extractNodes('lb-interaction-identifier', chatData)[1]
  local actionNode = prelude.extractNodes('lb-interaction-action', chatData)[1]

  local identifier = identifierNode and identifierNode.content
  local action = actionNode and actionNode.content

  if identifier and identifier ~= "" and action and action ~= "" then
    return identifier, action
  end
  return nil, nil
end

onStart = async(function(tid)
  local mode = getGlobalVar(tid, "toggle_lightboard.active") or "0"
  if mode == "0" then
    return
  end

  setTriggerId(tid)

  local fullChat = getFullChat(tid)
  local lastChat = fullChat[#fullChat]
  local secondLastChat = fullChat[#fullChat - 1]

  -- Try: last chat is action (no direction)
  local identifier, action = extractInteraction(lastChat.data)
  if identifier then
    stopChat(tid)
    local success, result = pcall(interact, fullChat, identifier, action, '(User provided no direction.)')
    if success then
      removeChat(tid, -1)
    else
      alertError(tid, "[LightBoard] 상호작용 " .. identifier .. " 실패. 개발자에게 문의하세요.\n" .. tostring(result))
    end
    return
  end

  -- Try: second last is action, last is direction
  if not secondLastChat or secondLastChat.role ~= 'user' then
    return
  end

  identifier, action = extractInteraction(secondLastChat.data)
  if not identifier then
    return
  end

  local direction = lastChat.data
  if not direction or direction == "" then
    direction = '(User provided no direction.)'
  end

  stopChat(tid)

  local success, result = pcall(interact, fullChat, identifier, action, direction)
  if success then
    removeChat(tid, -2)
    removeChat(tid, -1)
  else
    alertError(tid, "[LightBoard] 상호작용 " .. identifier .. " 실패. 개발자에게 문의하세요.\n" .. tostring(result))
  end
end)

-- Extract LBDATA blocks, send as system messages
listenEdit(
  "editRequest",
  function(tid, data)
    if getGlobalVar(tid, 'toggle_lightboard.sendAsSystem') == '0' then
      return data
    end

    setTriggerId(tid)

    for i = #data, 1, -1 do
      local msg = data[i]
      if msg.role == 'assistant' then
        local content = msg.content
        local pattern = "%-%-%-\n%[LBDATA START%](.-)%[LBDATA END%]\n%-%-%-"

        local s, e, inner = string.find(content, pattern)

        if s then
          -- Remove the entire block from the original message
          msg.content = content:sub(1, s - 1) .. content:sub(e + 1)

          if inner then
            local trimmed = prelude.trim(inner)
            if trimmed and trimmed ~= "" then
              -- Insert new system message after the current message
              table.insert(data, i + 1, { role = "system", content = '[LBDATA START]\n' .. trimmed .. '\n[LBDATA END]' })
            end
          end
        end
      end
    end

    return data
  end
)

dangerouslyCleanseWholeChat = async(function(tid)
  setTriggerId(tid)

  local cleanseTarget = prelude.trim(alertInput(tid,
      '삭제할 태그의 이름만 입력하세요.\n<lightboard-module-alpha> => lightboard-module-alpha\n태그 이름은 편집 버튼을 눌러서 확인하세요.\n\n아무것도 입력하지 않으면 취소합니다.')
    :await())
  if not cleanseTarget or cleanseTarget == '' then
    return
  end

  local confirm = alertConfirm(tid,
    '주의: 되돌릴 수 없습니다. 최소한의 처리만 하므로 부작용이 있을 수도 있습니다.\n정말 <' .. cleanseTarget .. '> 태그를 모두 삭제하시겠습니까?'):await()
  if not confirm then
    return
  end

  confirm = alertConfirm(tid,
    '경고: 지금이라도 백업하세요. 오류가 발생해서 텍스트가 엉망이 되어도 되돌릴 수 없습니다.\n정말 <' .. cleanseTarget .. '> 태그를 모두 삭제하시겠습니까?'):await()
  if not confirm then
    return
  end

  local fullChat = getFullChat(tid)
  local cleansedChat = {}

  -- -1 = cleaner button
  for i = 1, #fullChat do
    local chat = fullChat[i]
    if chat.role == 'char' then
      local originalContent = chat.data
      local modifiedContent = originalContent

      while true do
        local newContent, _ = removeNode(modifiedContent, cleanseTarget)
        if newContent == modifiedContent then
          break
        end
        modifiedContent = newContent
      end
      chat.data = modifiedContent
    end
    table.insert(cleansedChat, chat)
  end

  setFullChat(tid, cleansedChat)
  reloadDisplay(tid)

  alertNormal(tid, '⌛ 정리 완료.')
end)
