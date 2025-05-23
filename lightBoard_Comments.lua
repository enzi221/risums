--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Comments

--- @param s string
--- @return string
local function trim(s)
  -- Remove leading whitespace (%s* at the start ^)
  s = string.gsub(s, "^%s*", "")
  -- Remove trailing whitespace (%s* at the end $)
  s = string.gsub(s, "%s*$", "")
  return s
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

---@param tier string
---@return string
local function grantMedal(tier)
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

--- Renders a node into HTML.
--- @param triggerId string
--- @param block table
--- @return string
local function render(triggerId, block)
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

    local metadata = parseBlock(postBlock, { "Post", "Comment" })
    local authorTierEnd = metadata["Author"]:find(":")
    if authorTierEnd then
      metadata["AuthorTier"] = metadata["Author"]:sub(1, authorTierEnd - 1)
      metadata["Author"] = metadata["Author"]:sub(authorTierEnd + 1)
    end

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
      local commentAuthorTierEnd = commentMetadata["Author"]:find(":")
      if commentAuthorTierEnd then
        commentMetadata["AuthorTier"] = commentMetadata["Author"]:sub(1, commentAuthorTierEnd - 1)
        commentMetadata["Author"] = commentMetadata["Author"]:sub(commentAuthorTierEnd + 1)
      end
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

  local html = {
    '<div class="lb-module-root" data-id="lightboard-comment">',
    '<details class="lb-collapsible" name="lightboard-comment"><summary class="lb-opener"><span>댓글</span></summary>',
    '<div class="lb-comment-container">'
  }

  -- 게시글 루프
  if #posts > 0 then
    for i, post in ipairs(posts) do
      if post.content then
        local postAuthor = escapeHtml(post.author or "ㅇㅇ")
        local postAuthorTier = post.authorTier or ""
        local postContent = escapeHtml(post.content or ""):gsub("\n", "<br>"):gsub("\\n", "<br>")
        local postDownvotes = escapeHtml(post.downvotes or "-")
        local postTime = escapeHtml(post.time or "-")
        local postUpvotes = escapeHtml(post.upvotes or "-")

        table.insert(html, '<div class="lb-comment-card" style="animation-delay:' .. (i - 1) * 0.1 .. 's">')
        table.insert(html, '<div class="lb-comment-top"><div class="lb-comment-header">')

        -- <div style="display: flex; align-items: center;"><div class="lb-comment-avatar">' ..
        --   utf8sub(postAuthor, 1, 1) ..
        --   '</div>

        table.insert(html,
          '<div class="lb-comment-author-details"><span class="lb-comment-author">' ..
          grantMedal(postAuthorTier) ..
          postAuthor .. '</span><div class="lb-comment-timestamp">' .. postTime .. '</div></div>')
        table.insert(html,
          '<div class="lb-comment-actions"><button type="button" class="lb-comment-action-button" data-like>👍 <span class="lb-comment-count">' ..
          postUpvotes ..
          '</span></button><button type="button" class="lb-comment-action-button"  data-dislike>👎 <span class="lb-comment-count">' ..
          postDownvotes .. '</span></button></div>')

        table.insert(html, '</div>')                                                              -- comment-header

        table.insert(html, '<span class="lb-comment-content">' .. postContent .. '</span></div>') -- comment-top

        local commentCount = #post.comments

        if commentCount > 0 then
          table.insert(html, '<div class="lb-comment-replies-section">')

          for _, comment in ipairs(post.comments) do
            local commentAuthor = escapeHtml(comment.author or "ㅇㅇ")
            local commentAuthorTier = comment.authorTier or ""
            local commentContent = escapeHtml(comment.content or ""):gsub("\n", "<br>"):gsub("\\n", "<br>")
            local commentTime = escapeHtml(comment.time or "")

            -- <div class="lb-comment-reply-avatar">' ..
            --   utf8sub(commentAuthor, 1, 1) ..
            --   '</div>

            table.insert(html, '<div class="lb-comment-reply-card">')
            table.insert(html,
              '<div class="lb-comment-reply-header"><div class="lb-comment-author-details"><span class="lb-comment-author">' ..
              grantMedal(commentAuthorTier) ..
              commentAuthor .. '</span><div class="lb-comment-timestamp">' .. commentTime .. '</div></div></div>')
            table.insert(html, '<span class="lb-comment-reply-content">' .. commentContent .. '</span>')
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

  table.insert(html, "</div>")     -- comment-module-container
  table.insert(html, "</details>") -- collapsible
  table.insert(html,
    '<button class="lb-reroll" risu-btn="lb-reroll__lightboard-comments" type="button"><lb-reroll-icon /></button>')
  table.insert(html, "</div>") -- module-rerollable

  return table.concat(html, "")
end

listenEdit(
  "editDisplay",
  function(triggerId, data)
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
        local processSuccess, result = pcall(render, triggerId, match)
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
