---Extracts all `<lightboard-comments>` nodes.
---@param text string
---@return table[]
local function extractAllNodes(text)
  local results = {}
  local i = 1
  while true do
    local startIdx = text:find("<lightboard%-comments", i)
    if not startIdx then
      break
    end

    -- Find where the opening tag ends
    local tagEnd = text:find(">", startIdx)
    if not tagEnd then
      i = startIdx + 1
      goto continue
    end

    -- Directly find the closing tag without trying to extract the tag name
    local closeStart = text:find("</lightboard%-comments>", tagEnd)
    if not closeStart then
      i = tagEnd + 1
      goto continue
    end

    local closeEnd = closeStart + 21 -- Length of "</lightboard-comments>"

    -- Extract content and board name
    local contentOnly = text:sub(tagEnd + 1, closeStart - 1)

    table.insert(
      results,
      {
        content = contentOnly,
        rangeStart = startIdx,
        rangeEnd = closeEnd
      }
    )

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
---@return table
local function parseBlock(block)
  local metadata = {}

  local tagStart = block:find("%[.-%]")
  if tagStart then
    block = block:sub(1, tagStart - 1)
  end

  local contentMatch = block:match("Content:(.-)$")
  if contentMatch then
    metadata["Content"] = contentMatch:gsub("^%s+", "")
    block = block:gsub("Content:.*$", "")
  end

  local authorEnd = block:find("|")

  local author = block:sub(1, authorEnd - 1)
  local authorTierEnd = author:find(":")

  if authorTierEnd then
    metadata["Author"] = author:sub(authorTierEnd + 1):gsub("%s+$", "")
    metadata["AuthorTier"] = author:sub(1, authorTierEnd - 1)
  else
    metadata["Author"] = author:gsub("%s+$", "")
    metadata["AuthorTier"] = nil
  end

  local rest = block:sub(authorEnd + 1)
  for part in rest:gmatch("([^|]+)") do
    local field, value = part:match("([^:]+):(.+)")
    if field and value then
      field = field:gsub("^%s+", ""):gsub("%s+$", "")
      value = value:gsub("^%s+", ""):gsub("%s+$", "")
      metadata[field] = value
    end
  end

  return metadata
end

---Renders a node into HTML.
---@param block table
---@return string
local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  local posts = {}
  local currentPost = nil

  for _, post in ipairs(extractBlocks("Post", rawContent)) do
    local postBlock = post:match("(.-)%[Comment%]")
    if not postBlock then
      -- No postBlock = no [Comment]
      postBlock = post
    end

    local metadata = parseBlock(postBlock)
    currentPost = {
      author = metadata["Author"],
      authorTier = metadata["AuthorTier"],
      comments = {},
      content = metadata["Content"],
      time = metadata["Time"],
      downvotes = metadata["Downvotes"] or 0,
      upvotes = metadata["Upvotes"] or 0,
    }

    for _, commentBlock in ipairs(extractBlocks("Comment", post)) do
      local commentMetadata = parseBlock(commentBlock)
      local comment = {
        author = commentMetadata["Author"],
        authorTier = commentMetadata["AuthorTier"],
        content = commentMetadata["Content"],
        time = metadata["Time"],
      }

      if comment.author or comment.content then
        table.insert(currentPost.comments, comment)
      end
    end

    table.insert(posts, currentPost)
  end

  local html = {}

  table.insert(
    html,
    '<details class="lb-comment-root"><summary class="lb-comment-open">🖥️ 라이트라 댓글 (열기/닫기)</summary>'
  )
  table.insert(html, '<div class="lb-comment-container">')

  -- 게시글 루프
  if #posts > 0 then
    for i, post in ipairs(posts) do
      if post.content then
        local postAuthor = escapeHtml(post.author or "ㅇㅇ")
        local postAuthorTier = post.authorTier or ""
        local postContent = escapeHtml(post.content or ""):gsub("\n", "<br>"):gsub("\\n", "<br>"):gsub("\r", "")
        local postDownvotes = escapeHtml(post.downvotes or "-")
        local postTime = escapeHtml(post.time or "-")
        local postUpvotes = escapeHtml(post.upvotes or "-")

        table.insert(html, '<div class="lb-comment-card">')
        table.insert(html, '<div class="lb-comment-header">')

        table.insert(html,
          '<div style="display: flex; align-items: center;"><div class="lb-comment-avatar">' ..
          utf8sub(postAuthor, 1, 1) ..
          '</div><div class="lb-comment-author-details"><span class="lb-comment-author">' ..
          grantMedal(postAuthorTier) ..
          postAuthor .. '</span><div class="lb-comment-timestamp">' .. postTime .. '</div></div></div>')
        table.insert(html,
          '<div class="lb-comment-actions"><button type="button" class="lb-comment-action-button" data-like>👍 <span class="lb-count">' ..
          postUpvotes ..
          '</span></button><button type="button" class="lb-comment-action-button"  data-dislike>👎 <span class="lb-count">' ..
          postDownvotes .. '</span></button></div>')

        table.insert(html, '</div>') -- comment-header

        table.insert(html, '<p class="lb-comment-content">' .. postContent .. '</p>')

        local commentCount = #post.comments

        if commentCount > 0 then
          table.insert(html, '<div class="lb-comment-replies-section">')

          for _, comment in ipairs(post.comments) do
            local commentAuthor = escapeHtml(comment.author or "ㅇㅇ")
            local commentAuthorTier = comment.authorTier or ""
            local commentContent = escapeHtml(comment.content or ""):gsub("\n", "<br>"):gsub("\\n", "<br>"):gsub("\r", "")
            local commentTime = escapeHtml(comment.time or "")

            table.insert(html, '<div class="lb-comment-reply-card">')
            table.insert(html,
              '<div class="lb-comment-reply-header"><div class="lb-comment-reply-avatar">' ..
              utf8sub(commentAuthor, 1, 1) ..
              '</div><div class="lb-comment-reply-author-details"><span class="lb-comment-reply-author">' ..
              grantMedal(commentAuthorTier) ..
              commentAuthor .. '</span><div class="lb-comment-reply-timestamp">' .. commentTime .. '</div></div></div>')
            table.insert(html, '<p class="lb-comment-reply-content">' .. commentContent .. '</p>')
            table.insert(html, '</div>')
          end

          table.insert(html, '</div>') -- replies-section
        end

        table.insert(html, '</div>') -- comment-card
      end
    end
  else
    table.insert(html, "<div style='padding: 20px; text-align: center; color: #888;'>표시할 게시글 없음</div>")
  end

  table.insert(html, "</div>") -- comment-module-container
  table.insert(html, "</details>")

  return table.concat(html, "")
end

listenEdit(
  "editDisplay",
  function(_, data)
    if not data or data == "" then
      return ""
    end

    local replacements = {}
    local output = ""
    local lastIndex = 1

    local success, result = pcall(extractAllNodes, data)
    if success then
      replacements = result
    else
      print("[LightBoard] Comments extraction failed:", tostring(result))
      return data
    end

    if replacements and #replacements > 0 then
      for i, match in ipairs(replacements) do
        if match.rangeStart > lastIndex then
          output = output .. data:sub(lastIndex, match.rangeStart - 1)
        end
        local processSuccess, result = pcall(render, match)
        if processSuccess then
          output = output .. result
        else
          print("[LightBoard] Comment parsing failed in block " .. i .. ":", tostring(result))
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
)

---@param str string
---@return string
function escapeHtml(str)
  if not str then
    return ""
  end
  str = string.gsub(str, "&", "&amp;")
  str = string.gsub(str, "<", "&lt;")
  str = string.gsub(str, ">", "&gt;")
  return str
end

---@param tier string
---@return string
function grantMedal(tier)
  local medal = ""
  if tier == "Gold" then
    medal = "🥇"
  elseif tier == "Silver" then
    medal = "🥈"
  elseif tier == "Bronze" then
    medal = "🥉"
  end

  return medal
end

---@param s string
---@param i number
---@param j number
function utf8sub(s, i, j)
  i = utf8.offset(s, i)
  j = utf8.offset(s, j + 1) - 1
  return string.sub(s, i, j)
end
