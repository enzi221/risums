--! Copyright (c) 2025-2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard Comments

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

--- Renders a node into HTML.
--- @param node Node
--- @param chatIndex number
--- @return string
local function render(node, chatIndex)
  local rawContent = node.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class CommentsCommentData
  ---@field author string
  ---@field authorTier string
  ---@field content string
  ---@field time string

  ---@class CommentsPostData
  ---@field author string
  ---@field authorTier string
  ---@field comments CommentsCommentData[]
  ---@field content string
  ---@field time string
  ---@field downvotes string
  ---@field upvotes string

  ---@type CommentsPostData[]
  local posts = prelude.toon.decode(node.content)

  for _, post in ipairs(posts) do
    post.author = post.author or "익명"

    local postAuthorSplat = prelude.split(post.author, ":")
    if #postAuthorSplat >= 2 then
      post.author = postAuthorSplat[2]
      post.authorTier = postAuthorSplat[1] or ""
    else
      post.authorTier = ""
    end

    for _, comment in ipairs(post.comments or {}) do
      comment.author = comment.author or "익명"

      local commentAuthorSplat = prelude.split(comment.author, ":")
      if #commentAuthorSplat >= 2 then
        comment.author = commentAuthorSplat[2]
        comment.authorTier = commentAuthorSplat[1] or ""
      else
        comment.authorTier = ""
      end
    end
  end

  local post_es = {}

  if #posts > 0 then
    for i, post in ipairs(posts) do
      if post.content then
        local comment_es = {}
        for j, comment in ipairs(post.comments or {}) do
          local comment_e = h.div['lb-comment-reply-card'] {
            h.div['lb-comment-author-details'] {
              h.span['lb-comment-author'] {
                grantMedal(comment.authorTier) .. comment.author,
              },
              h.div['lb-comment-timestamp'] {
                comment.time or "-",
              },
            },
            h.span['lb-comment-reply-content'] {
              comment.content,
            },
            h.span['lb-comment-delete-comment'] {
              h.button['lb-comment-icon-btn'] {
                risu_btn = 'lb-comments-delete/' .. chatIndex .. '_' .. i .. '_' .. j,
                type = 'button',
                h.lb_trash_icon { closed = true },
              },
            },
          }
          table.insert(comment_es, comment_e)
        end

        local repliesSection_e = nil
        if #comment_es > 0 then
          repliesSection_e = h.details['lb-comment-replies-section'] {
            name = 'lb-comment-replies',
            h.summary {
              "대댓글 " .. #comment_es .. "개",
            },
            comment_es
          }
        end

        table.insert(post_es, h.div['lb-comment-card'] {
          style = 'animation-delay:' .. (i - 1) * 0.1 .. 's',
          h.div['lb-comment-top'] {
            h.div['lb-comment-header'] {
              h.div['lb-comment-author-details'] {
                h.span['lb-comment-author'] {
                  grantMedal(post.authorTier) .. post.author,
                },
                h.div['lb-comment-timestamp'] {
                  post.time or "-",
                },
              },
              h.div['lb-comment-actions'] {
                h.span['lb-comment-action-button'] {
                  data_like = true,
                  '+',
                  h.span['lb-comment-count'] {
                    post.upvotes or '0',
                  },
                },
                h.span['lb-comment-action-button'] {
                  data_dislike = true,
                  '-',
                  h.span['lb-comment-count'] {
                    post.downvotes or '0',
                  },
                },
                h.button['lb-comment-add-reply'] {
                  risu_btn = 'lb-comments-delete/' .. chatIndex .. '_' .. i,
                  type = 'button',
                  h.lb_trash_icon { closed = true },
                  h.span "삭제"
                },
                h.button['lb-comment-add-reply'] {
                  risu_btn = "lb-interaction__lb-comments__AddComment/Author:" .. post.author .. "(" .. post.time .. ")",
                  type = "button",
                  h.lb_comment_icon { closed = true },
                  h.span "대댓글 달기"
                },
              },
            },
            h.span['lb-comment-content'] {
              post.content,
            },
            repliesSection_e,
          },
        })
      end
    end
  else
    post_es = h.div['lb-no-comments'] {
      style = 'padding: 20px; text-align: center; color: #888;',
      '표시할 게시글 없음',
    }
  end

  local html = h.div['lb-module-root'] {
    data_id = 'lb-comments',
    h.details['lb-collapsible'] {
      name = 'lb-comments',
      h.summary['lb-opener'] {
        h.span '댓글',
      },
      h.div['lb-comment-container'] {
        post_es,
        h.div['lb-comment-card lb-comment-add-post-card'] {
          style = 'animation-delay:' .. #post_es * 0.1 .. 's',
          h.button['lb-comment-add-post'] {
            risu_btn = "lb-interaction__lb-comments__AddPost",
            type = "button",
            h.span['lb-comment-add-post-header'] "댓글 작성",
            h.span['lb-comment-add-post-textarea'] {
              "사이트 관리 규정에 어긋나는 의견글은 예고없이 삭제될 수 있습니다.",
              h.span['lb-comment-add-post-button'] {
                h.span "제출"
              }
            },
          },
        }
      },
    },
    h.button['lb-reroll'] {
      risu_btn = 'lb-reroll__lb-comments',
      type = 'button',
      h.lb_reroll_icon {
        closed = true
      },
    },
  }

  return tostring(html)
end

--- @param s string
--- @return string
local function escape(s)
  if not s then return '' end
  return (s:gsub('\n', '\\n'):gsub('\t', '\\t'))
end

--- @param posts CommentsPostData[]
--- @return string
local function encodePosts(posts)
  local lines = { '[' .. #posts .. '|]:' }
  for _, post in ipairs(posts) do
    local authorField = post.author
    if post.authorTier and post.authorTier ~= '' then
      authorField = post.authorTier .. ':' .. post.author
    end
    table.insert(lines, '  - author: ' .. escape(authorField))
    table.insert(lines, '    time: ' .. escape(post.time or ''))
    table.insert(lines, '    upvotes: ' .. (post.upvotes or '0'))
    table.insert(lines, '    downvotes: ' .. (post.downvotes or '0'))
    table.insert(lines, '    content: ' .. escape(post.content or ''))
    local comments = post.comments or {}
    if #comments == 0 then
      table.insert(lines, '    comments[0|]:')
    else
      table.insert(lines, '    comments[' .. #comments .. '|]{content|time|author}:')
      for _, c in ipairs(comments) do
        local cAuthor = c.author
        if c.authorTier and c.authorTier ~= '' then
          cAuthor = c.authorTier .. ':' .. c.author
        end
        table.insert(lines, '      ' .. escape(c.content or '') .. '|' .. escape(c.time or '') .. '|' .. escape(cAuthor))
      end
    end
  end
  return table.concat(lines, '\n')
end

local function main(data, meta)
  if not data or data == "" then
    return ""
  end

  local extractionSuccess, extractionResult = pcall(prelude.queryNodes, 'lb-comments', data)
  if not extractionSuccess then
    print("[LightBoard] Comments extraction failed:", tostring(extractionResult))
    return data
  end

  local lastResult = extractionResult and extractionResult[#extractionResult] or nil
  if not lastResult then
    return data
  end

  local output = ''
  local lastIndex = 1

  for i = 1, #extractionResult do
    local match = extractionResult[i]
    if match.rangeStart > lastIndex then
      output = output .. data:sub(lastIndex, match.rangeStart - 1)
    end
    if i == #extractionResult then
      -- render lastResult in its original position
      local processSuccess, processResult = pcall(render, lastResult, meta and meta.index or 0)
      if processSuccess then
        output = output .. processResult
      else
        output = output .. '<lb-lazy id="lb-comments">오류: ' .. tostring(processResult) .. '</lb-lazy>'
      end
    end
    lastIndex = match.rangeEnd + 1
  end

  return output .. data:sub(lastIndex)
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

    local success, result = pcall(main, data, meta)
    if success then
      return result
    else
      return data .. '<lb-lazy id="lb-comments">오류: ' .. tostring(result) .. '</lb-lazy>'
    end
  end
)

onButtonClick = async(function(tid, code)
  local prefix = 'lb%-comments%-delete/'
  local _, prefixEnd = string.find(code, prefix)

  if not prefixEnd then
    return
  end

  setTriggerId(tid)

  local body = code:sub(prefixEnd + 1)
  if body == '' then
    return
  end

  local parts = prelude.split(body, '_')
  local chatIndex = tonumber(parts[1])
  local postIndex = tonumber(parts[2])
  local commentIndex = parts[3] and tonumber(parts[3]) or nil

  local deathMessage = (chatIndex or '?') .. '번 채팅의 ' .. (postIndex or '?') .. '번 글을 찾을 수 없습니다.'

  if not chatIndex or not postIndex then
    alertNormal(tid, deathMessage)
    return
  end

  local targetType = commentIndex and '댓글' or '글'
  local confirmed = alertConfirm(tid, '정말 이 ' .. targetType .. '을 지우시겠습니까?'):await()
  if not confirmed then
    return
  end

  local chatData = getChat(tid, chatIndex)
  if not chatData or not chatData.data then
    alertNormal(tid, deathMessage)
    return
  end

  local extractionSuccess, extractionResult = pcall(prelude.queryNodes, 'lb-comments', chatData.data)
  if not extractionSuccess or not extractionResult or #extractionResult == 0 then
    alertNormal(tid, deathMessage)
    return
  end

  local lastResult = extractionResult[#extractionResult]
  local posts = prelude.toon.decode(lastResult.content)

  for _, post in ipairs(posts) do
    post.author = post.author or '익명'
    local postAuthorSplat = prelude.split(post.author, ':')
    if #postAuthorSplat >= 2 then
      post.author = postAuthorSplat[2]
      post.authorTier = postAuthorSplat[1] or ''
    else
      post.authorTier = ''
    end
    for _, comment in ipairs(post.comments or {}) do
      comment.author = comment.author or '익명'
      local commentAuthorSplat = prelude.split(comment.author, ':')
      if #commentAuthorSplat >= 2 then
        comment.author = commentAuthorSplat[2]
        comment.authorTier = commentAuthorSplat[1] or ''
      else
        comment.authorTier = ''
      end
    end
  end

  if postIndex < 1 or postIndex > #posts then
    alertNormal(tid, deathMessage)
    return
  end

  if commentIndex then
    local post = posts[postIndex]
    if not post.comments or commentIndex < 1 or commentIndex > #post.comments then
      alertNormal(tid, chatIndex .. '번 채팅 ' .. postIndex .. '번 글의 ' .. commentIndex .. '번 댓글을 찾을 수 없습니다.')
      return
    end
    table.remove(post.comments, commentIndex)
  else
    table.remove(posts, postIndex)
  end

  local newContent = encodePosts(posts)
  local newData = chatData.data:sub(1, lastResult.rangeStart - 1)
      .. lastResult.openTag .. '\n'
      .. newContent .. '\n'
      .. '</' .. lastResult.tagName .. '>'
      .. chatData.data:sub(lastResult.rangeEnd + 1)

  setChat(tid, chatIndex, newData)
end)
