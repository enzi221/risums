---Extracts all `<lightboard-hn>` nodes.
---@param text string
---@return string[]
local function extractAllNodes(text)
  local results = {}
  local i = 1
  while true do
    -- Find opening tag for lightboard-hn
    local startIdx = text:find("<lightboard%-hn", i)
    if not startIdx then
      break
    end

    -- Find the name attribute
    local nameStart = text:find("name=", startIdx)
    if not nameStart or nameStart > startIdx + 20 then -- Only look for name= within a reasonable distance
      i = startIdx + 1
      goto continue
    end

    -- Find where the opening tag ends
    local tagEnd = text:find(">", nameStart)
    if not tagEnd then
      i = startIdx + 1
      goto continue
    end

    -- Extract the name value from the name= attribute
    local nameValueStart = nameStart + 5 -- "name=" length
    local quoteChar = text:sub(nameValueStart, nameValueStart)
    local nameEnd

    if quoteChar == '"' or quoteChar == "'" then
      nameValueStart = nameValueStart + 1 -- Skip the opening quote
      nameEnd = text:find(quoteChar, nameValueStart)
      if not nameEnd then
        i = startIdx + 1
        goto continue
      end
      nameEnd = nameEnd - 1 -- End before closing quote
    else
      nameEnd = text:find("[%s>]", nameValueStart)
      if not nameEnd then
        i = startIdx + 1
        goto continue
      end
      nameEnd = nameEnd - 1 -- End before space or >
    end

    -- Directly find the closing tag without trying to extract the tag name
    local closeStart = text:find("</lightboard%-hn>", tagEnd)
    if not closeStart then
      i = tagEnd + 1
      goto continue
    end

    local closeEnd = closeStart + 15 -- Length of "</lightboard-hn>"

    -- Extract content and board name
    local contentOnly = text:sub(tagEnd + 1, closeStart - 1)
    local boardName = text:sub(nameValueStart, nameEnd)

    table.insert(
      results,
      {
        content = contentOnly,
        boardName = boardName and boardName ~= "" and boardName or "헌터 게시판",
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

local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[HunterNet Error: Empty Content]"
  end

  local posts = {}
  local currentPost = nil

  for _, post in ipairs(extractBlocks("Post", rawContent)) do
    local postBlock = post:match("(.-)%[Comment%]")
    if not postBlock then
      -- No postBlock = no [Comment]
      postBlock = post
    end

    currentPost = { comments = {} }
    local metadata = extractFields(postBlock)

    currentPost.id = metadata["No"]
    currentPost.title = metadata["Title"]
    currentPost.date = metadata["Time"]
    currentPost.views = metadata["Views"]
    currentPost.upvotes = metadata["Upvotes"]
    currentPost.content = metadata["Content"]

    if metadata["Author"] then
      currentPost.author = parseAuthorInfo(metadata["Author"])
      currentPost.hunterRank = currentPost.author.rank
      currentPost.status = currentPost.author.status
    end

    for _, commentBlock in ipairs(extractBlocks("Comment", post)) do
      local commentMetadata = extractFields(commentBlock)
      local comment = parseAuthorInfo(commentMetadata["Author"])

      comment.text = commentMetadata["Content"]

      if comment.name or comment.text then
        table.insert(currentPost.comments, comment)
      end
    end

    if currentPost.id then
      table.insert(posts, currentPost)
    end
  end

  local boardName = block.boardName
  local html = {}

  table.insert(
    html,
    '<details class="hunter-details"><summary><span>📂 ' .. escapeHtml(boardName) .. " (열기/닫기)</span></summary>"
  )

  table.insert(
    html,
    '<div class="hunter-container"><div class="hunter-header"><h1>' ..
    escapeHtml(boardName) ..
    '</h1><div class="hunter-top-links"><span onclick="void(0);">헌터넷 정보</span> | <span onclick="void(0);">설정</span> | <span onclick="void(0);">퀘스트 게시판</span> | <span onclick="void(0);">프로필</span> | <span onclick="void(0);">길드 정보</span> | <span onclick="void(0);">새로고침</span></div></div><div class="hunter-options"><div class="tab-menu"><button class="tab-button active">전체글</button> <button class="tab-button">공지사항</button> <button class="tab-button">퀘스트</button></div><div class="hunter-actions"><select name="viewCount"><option value="30">30개</option><option value="50">50개</option><option value="100">100개</option></select><span onclick="void(0);" class="write-button"><i>📝</i> 글쓰기</span></div></div><div class="post-list-container"><div class="post-list-header"><div class="header-item col-num">번호</div> <div class="header-item col-title">제목</div> <div class="header-item col-writer">작성자</div> <div class="header-item col-date">등록일</div> <div class="header-item col-view">조회</div> <div class="header-item col-rank">추천</div></div><div class="post-list-body">'
  )

  -- 게시글 루프
  if #posts > 0 then
    for i, post in ipairs(posts) do
      if post.id and post.title and post.content then
        local postId = escapeHtml(post.id)
        local postTitle = escapeHtml(post.title or "N/T")
        local postDate = escapeHtml(post.date or "-")
        local postViews = escapeHtml(post.views or "-")
        local postRank = escapeHtml(post.upvotes or "-")
        local postContent = escapeHtml(post.content or "")
        postContent = postContent:gsub("\n", "<br>"):gsub("\\n", "<br>"):gsub("\r", "")

        local author = post.author or {}
        local writerName = author.name or "-"
        local writerIp = author.ip
        local hunterRank = author.rank or ""
        local writerStatus = author.status or "Floater"

        local hunterRankDisplay = ""
        if hunterRank and hunterRank ~= "" then
          hunterRankDisplay = '<span class="hunter-level hunter-rank-' ..
              string.lower(hunterRank) .. '">' .. hunterRank .. "</span>"
        end

        local statusIcon = ""
        if writerStatus == "Fixed" then
          statusIcon = '<span class="icon-fixed">고</span>'
        elseif writerStatus == "Semi" then
          statusIcon = '<span class="icon-semi">반</span>'
        end

        local writerDisplay =
            hunterRankDisplay ..
            escapeHtml(writerName) ..
            statusIcon ..
            (writerIp and "<span class='writer-ip'>(" .. escapeHtml(writerIp) .. ")</span>" or "")

        local commentCount = #post.comments
        local commentCountDisplay =
            commentCount > 0 and (' <span class="comment-count">[' .. commentCount .. "]</span>") or ""

        local commentsHtml = {}
        if commentCount > 0 then
          for _, comment in ipairs(post.comments) do
            local authorName = comment.name or "ㅇㅇ"
            local authorIp = comment.ip
            local commentText = comment.text or ""
            local commentStatus = comment.status or "Floater"

            local commentHunterRank = comment.rank or ""

            local commentHunterRankDisplay = ""
            if commentHunterRank and commentHunterRank ~= "" then
              commentHunterRankDisplay = '<span class="hunter-level hunter-rank-' ..
                  string.lower(commentHunterRank) .. '">' .. commentHunterRank .. "</span>"
            end

            local statusIcon = ""
            if commentStatus == "Fixed" then
              statusIcon = '<span class="icon-fixed">고</span>'
            elseif commentStatus == "Semi" then
              statusIcon = '<span class="icon-semi">반</span>'
            end

            local authorDisplay =
                commentHunterRankDisplay ..
                escapeHtml(authorName) ..
                statusIcon ..
                (authorIp and '<span class="writer-ip">(' .. escapeHtml(authorIp) .. ")</span>" or
                  "")

            local escapedCommentText = escapeHtml(commentText)
            escapedCommentText = string.gsub(escapedCommentText, "\n", "<br>")
            escapedCommentText = string.gsub(escapedCommentText, "\r", "")
            local finalCommentHtmlText = (escapedCommentText ~= "" and escapedCommentText or "(내용 없음)")

            table.insert(commentsHtml, '<li class="comment-item">')
            table.insert(commentsHtml, '<div class="comment-author">' .. authorDisplay .. "</div>")
            table.insert(commentsHtml, '<div class="comment-text">' .. finalCommentHtmlText .. "</div>")
            table.insert(commentsHtml, "</li>")
          end
        end

        local idPrefix = math.random()

        -- 게시글 HTML 조립
        table.insert(html, '<div class="post-item">')
        table.insert(html, '<input id="' .. idPrefix .. postId .. '" type="checkbox" class="post-toggle">')
        table.insert(
          html,
          '<div class="post-row">' ..
          '<div class="post-cell col-num">' ..
          postId ..
          "</div>" ..
          '<div class="post-cell col-title"><label for="' ..
          idPrefix .. postId ..
          '" class="post-title-label"><span>' ..
          postTitle ..
          commentCountDisplay ..
          "</span></label></div>" ..
          '<div class="post-cell col-writer">' ..
          writerDisplay ..
          "</div>" ..
          '<div class="post-cell col-date">' ..
          postDate ..
          "</div>" ..
          '<div class="post-cell col-view">' ..
          postViews ..
          "</div>" ..
          '<div class="post-cell col-rank">' ..
          postRank ..
          "</div></div>"
        )
        table.insert(
          html,
          '<div class="post-content-wrapper"><div class="post-view-header">' ..
          '<div class="post-view-title">' ..
          postTitle ..
          "</div>" ..
          '<div class="post-view-info"><span class="author">' ..
          writerDisplay ..
          '</span><span class="separator">|</span><span>등록일: ' ..
          postDate ..
          '</span><span class="separator">|</span><span>조회: ' ..
          postViews ..
          '</span><span class="separator">|</span><span>추천: ' ..
          postRank ..
          "</span></div></div>" ..
          '<div class="post-full-content"><span>' ..
          postContent .. "</span></div>"
        )
        if commentCount > 0 then
          table.insert(
            html,
            '<div class="comments-section"><h4>댓글 ' ..
            commentCount ..
            '</h4><ul class="comment-list">' .. table.concat(commentsHtml, "\n") .. "</ul></div>"
          )
        end
        table.insert(html, "</div></div>") -- post-content-wrapper & post-item
      end
    end
  else
    table.insert(html, "<div style='padding: 20px; text-align: center; color: #888;'>표시할 게시글 없음</div>")
  end

  -- Close the main structure
  table.insert(html, "</div></div></div>") -- post-list-body, post-list-container, hunter-container

  -- details/summary 토글 종료
  table.insert(html, "</details>")

  return table.concat(html, "\n")
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
      return data
    end

    if replacements and #replacements > 0 then
      for i, match in ipairs(replacements) do
        if match.rangeStart > lastIndex then
          output = output .. data:sub(lastIndex, match.rangeStart - 1)
        end
        local processSuccess, processedContent = pcall(render, match)
        if processSuccess then
          output = output .. processedContent
        else
          print(string.format("[listenEdit] !!! processHnBlock 오류 (블록 %d): %s", i, processedContent))
          output = output .. "<!-- HunterNet Block Error -->"
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

function escapeHtml(str)
  if not str then
    return ""
  end
  str = string.gsub(str, "&", "&amp;")
  str = string.gsub(str, "<", "&lt;")
  str = string.gsub(str, ">", "&gt;")
  return str
end

function extractFields(block)
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

  for part in block:gmatch("([^|]+)") do
    local field, value = part:match("([^:]+):(.+)")
    if field and value then
      field = field:gsub("^%s+", ""):gsub("%s+$", "")
      value = value:gsub("^%s+", ""):gsub("%s+$", "")
      metadata[field] = value
    end
  end

  return metadata
end

function parseAuthorInfo(authorText)
  local status = "Floater"

  if authorText:match("^F:") then
    status = "Fixed"
    authorText = authorText:sub(3)
  elseif authorText:match("^S:") then
    status = "Semi"
    authorText = authorText:sub(3)
  end

  local authorName, ip, rank = authorText:match("([^%(:]*)%(?([^%):]*)%)?:?([^%s]*)")
  authorName = authorName:gsub("%s+$", "")

  if ip and ip == "" then
    ip = nil
  end

  return {
    name = authorName,
    ip = ip,
    rank = rank,
    status = status
  }
end
