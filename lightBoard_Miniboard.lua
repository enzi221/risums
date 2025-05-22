--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Miniboard

--- @param s string
--- @return string
local function trim(s)
  -- Remove leading whitespace (%s* at the start ^)
  s = string.gsub(s, "^%s*", "")
  -- Remove trailing whitespace (%s* at the end $)
  s = string.gsub(s, "%s*$", "")
  return s
end

---Extracts all nodes.
---@param text string
---@return table[]
local function extractAllNodes(tagNameRaw, text)
  local results = {}
  local i = 1

  local tagName = tagNameRaw:gsub("(%W)", "%%%1")

  while true do
    local startIdx = text:find("<" .. tagName, i)
    if not startIdx then
      break
    end

    -- Find where the opening tag ends
    local tagEnd = text:find(">", startIdx)
    if not tagEnd then
      i = startIdx + 1
      goto continue
    end

    -- Extract all attributes from the opening tag
    local openTagContent = text:sub(
      startIdx + #("<" .. tagNameRaw),
      tagEnd - 1
    )
    local attrs = {}

    -- quoted attributes: key="val" or key='val'
    for key, quote, val in openTagContent:gmatch("([%w:_-]+)%s*=%s*(['\"])(.-)%2") do
      attrs[key] = val
    end

    -- unquoted attributes: key=val
    for key, val in openTagContent:gmatch("([%w:_-]+)%s*=%s*([^%s\"'>]+)") do
      if not attrs[key] then attrs[key] = val end
    end

    -- Find closing tag
    local closeStart, _ = text:find("</" .. tagName .. ">", tagEnd)
    if not closeStart then
      i = tagEnd + 1
      goto continue
    end
    local closeEnd = closeStart + #("</" .. tagNameRaw .. ">") - 1

    -- Extract inner content
    local contentOnly = text:sub(tagEnd + 1, closeStart - 1)

    table.insert(results, {
      content    = contentOnly,
      attributes = attrs,
      rangeStart = startIdx,
      rangeEnd   = closeEnd
    })

    i = closeEnd + 1
    ::continue::
  end

  return results
end

---Extracts contents between all [Tag] ... [Tag].
---@param tag string
---@param content string
---@return string[]
local function extractBlocks(tag, content)
  local results = {}
  local openTag = "[" .. tag .. "]"
  local pos = 1

  while true do
    local s, e = content:find(openTag, pos, true)
    if not s then break end

    -- find next occurrence of the same tag
    local nextS = content:find(openTag, e + 1, true)
    if nextS then
      table.insert(results, content:sub(e + 1, nextS - 1))
      pos = nextS
    else
      -- last segment
      table.insert(results, content:sub(e + 1))
      break
    end
  end

  return results
end

---Parses a block into a proper table.
---@param block string
---@param tagToEnd string[]?
---@return table
local function parseBlock(block, tagToEnd)
  local metadata = {}

  if type(tagToEnd) == "table" then
    for _, tag in ipairs(tagToEnd) do
      if tag and tag ~= "" then
        local currentPattern = "%[" .. tag:gsub("(%W)", "%%%1") .. "%]"
        local tagStartMatch = block:find(currentPattern)
        if tagStartMatch then
          block = block:sub(1, tagStartMatch - 1)
          break
        end
      end
    end
  end

  local contentMatch = block:match("Content:(.-)$")
  if contentMatch then
    metadata["Content"] = trim(contentMatch)
    block = block:gsub("Content:.*$", "")
  end

  for part in block:gmatch("([^|]+)") do
    local field, value = part:match("([^:]+):(.+)")
    if field and value then
      field = trim(field)
      value = trim(value)
      metadata[field] = value
    end
  end

  return metadata
end

---@param str string
---@return string
local function escapeHtml(str)
  if not str then
    return ""
  end
  str = string.gsub(str, "&", "&amp;")
  str = string.gsub(str, "<", "&lt;")
  str = string.gsub(str, ">", "&gt;")
  return str
end

---Renders a node into HTML.
---@param block table
---@return string
local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  local postsData = {} -- Renamed from 'posts' to avoid confusion
  local currentPostData = nil

  for _, postText in ipairs(extractBlocks("Post", rawContent)) do
    local postBlock = postText:match("(.-)%[Comment%]")
    if not postBlock then
      -- No postBlock = no [Comment]
      postBlock = postText
    end

    local metadata = parseBlock(postBlock, { "Post", "Comment" })
    currentPostData = {
      author = metadata["Author"],
      comments = {},
      content = metadata["Content"],
      time = metadata["Time"],
      title = metadata["Title"],
      downvotes = metadata["Downvotes"] or 0,
      upvotes = metadata["Upvotes"] or 0,
    }

    for _, commentBlockText in ipairs(extractBlocks("Comment", postText)) do
      local commentMetadata = parseBlock(commentBlockText)
      local comment = {
        author = commentMetadata["Author"],
        content = commentMetadata["Content"],
        time = commentMetadata["Time"],
      }

      if comment.author or comment.content then
        table.insert(currentPostData.comments, comment)
      end
    end

    table.insert(postsData, currentPostData)
  end

  local html = {}
  local boardTitle = escapeHtml(block.attributes.name or "미니보드")

  table.insert(html, '<details class="lb-module-root lb-module-root-animated" name="lightboard-miniboard">')
  table.insert(html, '  <summary class="lb-opener"><span>♦️미니보드</span></summary>')
  table.insert(html, '  <div class="lb-mini-board-wrapper">')
  table.insert(html, '    <div class="lb-mini-board-title">' .. boardTitle .. '</div>')
  table.insert(html, '    <div class="lb-mini-posts-list">')

  if #postsData > 0 then
    for i, post in ipairs(postsData) do
      local postTitle = escapeHtml(post.title or "제목 없음")
      local postAuthor = escapeHtml(post.author or "익명")
      local postTime = escapeHtml(post.time or "시간 정보 없음")
      -- Ensure upvotes and downvotes are numbers
      local postUpvotes = tonumber(post.upvotes) or 0
      local postDownvotes = tonumber(post.downvotes) or 0
      local postContent = escapeHtml(post.content or ""):gsub("\n", "<br>"):gsub("\\n", "<br>")

      table.insert(html, '      <details class="lb-mini-post" name="lightboard-miniboard-post">')
      table.insert(html, '        <summary class="lb-mini-post-summary">')
      table.insert(html, '          <div class="lb-mini-post-title-container">')
      table.insert(html, '            <span class="lb-mini-post-title-text">' .. postTitle .. '</span>')
      table.insert(html, '            <div class="lb-mini-post-summary-meta">')
      table.insert(html, '              <span class="lb-mini-author">' .. postAuthor .. '</span>')
      table.insert(html, '              <span class="lb-mini-time">' .. postTime .. '</span>')
      table.insert(html, '              <span class="lb-mini-votes">')
      table.insert(html, '                <span class="lb-mini-summary-like">▲ ' .. postUpvotes .. '</span>')
      table.insert(html, '                <span class="lb-mini-summary-dislike">▼ ' .. postDownvotes .. '</span>')
      table.insert(html, '              </span>') -- close lb-mini-votes
      table.insert(html, '            </div>')    -- close lb-mini-post-summary-meta
      table.insert(html, '          </div>')      -- close lb-mini-post-title-container
      table.insert(html, '        </summary>')    -- close lb-mini-post-summary

      table.insert(html, '        <div class="lb-mini-post-content">')
      table.insert(html, '          <span class="lb-mini-post-body-text">' .. postContent .. '</span>')

      if #post.comments > 0 then
        table.insert(html, '          <div class="lb-mini-comments-section">')
        table.insert(html, '            <div class="lb-mini-comments-title">댓글 (' .. #post.comments .. ')</div>')
        for _, comment in ipairs(post.comments) do
          local commentAuthor = escapeHtml(comment.author or "익명")
          local commentTime = escapeHtml(comment.time or "시간 정보 없음")
          local commentContent = escapeHtml(comment.content or ""):gsub("\n", "<br>"):gsub("\\n", "<br>")

          table.insert(html, '            <div class="lb-mini-comment">')
          table.insert(html, '              <div class="lb-mini-comment-meta">')
          table.insert(html, '                <span class="lb-mini-author">' .. commentAuthor .. '</span>')
          table.insert(html, '                <span class="lb-mini-time">(' .. commentTime .. ')</span>')
          table.insert(html, '              </div>') -- close lb-mini-comment-meta
          table.insert(html, '              <span class="lb-mini-comment-text">' .. commentContent .. '</span>')
          table.insert(html, '            </div>')   -- close lb-mini-comment
        end
        table.insert(html, '          </div>')       -- close lb-mini-comments-section
      end

      table.insert(html, '        </div>')   -- close lb-mini-post-content
      table.insert(html, '      </details>') -- close lb-mini-post
    end
  else
    table.insert(html, "      <div style='padding: 20px; text-align: center; color: #888;'>표시할 게시글 없음</div>")
  end

  table.insert(html, '    </div>') -- close lb-mini-posts-list
  table.insert(html, '  </div>')   -- close lb-mini-board-wrapper
  table.insert(html, '</details>') -- close lb-module-root

  return table.concat(html, "\n")
end

local function main(_, data)
  if not data or data == "" then
    return ""
  end

  local output = ""
  local lastIndex = 1

  local success, extractionResult = pcall(extractAllNodes, "lightboard-miniboard", data)
  if success then
  else
    print("[LightBoard] Miniboard extraction failed:", tostring(extractionResult))
    return data
  end

  if extractionResult and #extractionResult > 0 then
    for i, match in ipairs(extractionResult) do
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      local processSuccess, renderResult = pcall(render, match)
      if processSuccess then
        output = output .. renderResult
      else
        print("[LightBoard] Miniboard parsing failed in block " .. i .. ":", tostring(renderResult))
        output = output .. "\n\n<!-- LightBoard Block Error -->"
      end
      lastIndex = match.rangeEnd + 1
    end
  else
    lastIndex = 1
  end

  if lastIndex <= #data then
    output = output .. data:sub(lastIndex)
  end

  return output
end

listenEdit(
  "editDisplay",
  function(triggerId, data)
    local success, result = pcall(main, triggerId, data)
    if success then
      return result
    else
      print("[LightBoard] Miniboard display failed:", tostring(result))
      return data
    end
  end
)
