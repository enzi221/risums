--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Comments

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
--- @param block table
--- @return string
local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class CommentsCommentData
  ---@field Author string
  ---@field AuthorTier string
  ---@field Content string
  ---@field Time string

  ---@class CommentsPostData
  ---@field Author string
  ---@field AuthorTier string
  ---@field Comments CommentsCommentData[]
  ---@field Content string
  ---@field Time string
  ---@field Downvotes string
  ---@field Upvotes string

  ---@type CommentsPostData[]
  local posts = {}

  for _, postBlock in ipairs(prelude.extractBlocks("Post", rawContent)) do
    ---@class CommentsPostData
    local postData = prelude.parseBlock(postBlock, { "Post", "Comment" })
    postData.Author = postData.Author or "익명"

    local postAuthorSplat = prelude.split(postData.Author, ":")
    if #postAuthorSplat >= 2 then
      postData.Author = postAuthorSplat[2]
      postData.AuthorTier = postAuthorSplat[1] or ""
    end

    postData.Comments = {}

    for _, commentBlock in ipairs(prelude.extractBlocks("Comment", postBlock)) do
      ---@type CommentsCommentData
      local commentData = prelude.parseBlock(commentBlock)
      commentData.Author = commentData.Author or "익명"

      local commentAuthorSplat = prelude.split(commentData.Author, ":")
      if #commentAuthorSplat >= 2 then
        commentData.Author = commentAuthorSplat[2]
        commentData.AuthorTier = commentAuthorSplat[1] or ""
      end

      table.insert(postData.Comments, commentData)
    end

    table.insert(posts, postData)
  end

  local post_es = {}

  if #posts > 0 then
    for i, post in ipairs(posts) do
      if post.Content then
        local comment_es = {}
        for _, comment in ipairs(post.Comments) do
          local comment_e = h.div['lb-comment-reply-card'] {
            h.div['lb-comment-author-details'] {
              h.span['lb-comment-author'] {
                grantMedal(comment.AuthorTier) .. comment.Author,
              },
              h.div['lb-comment-timestamp'] {
                comment.Time or "-",
              },
            },
            h.span['lb-comment-reply-content'] {
              comment.Content,
            },
          }
          table.insert(comment_es, comment_e)
        end

        local repliesSection_e = nil
        if #comment_es > 0 then
          repliesSection_e = h.details['lb-comment-replies-section'] {
            name = 'lightboard-comment-replies',
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
                  grantMedal(post.AuthorTier) .. post.Author,
                },
                h.div['lb-comment-timestamp'] {
                  post.Time or "-",
                },
              },
              h.div['lb-comment-actions'] {
                h.span['lb-comment-action-button'] {
                  data_like = true,
                  '+',
                  h.span['lb-comment-count'] {
                    post.Upvotes or '0',
                  },
                },
                h.span['lb-comment-action-button'] {
                  data_dislike = true,
                  '-',
                  h.span['lb-comment-count'] {
                    post.Downvotes or '0',
                  },
                },
                h.button['lb-comment-add-reply'] {
                  risu_btn = "lb-interaction__lightboard-comments__AddComment/Author:" .. post.Author .. "(" .. post.Time .. ")",
                  type = "button",
                  h.lb_comment_icon { closed = true },
                  h.span "대댓글 달기"
                },
              },
            },
            h.span['lb-comment-content'] {
              post.Content,
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
    data_id = 'lightboard-comment',
    h.details['lb-collapsible'] {
      name = 'lightboard-comment',
      h.summary['lb-opener'] {
        h.span '댓글',
      },
      h.div['lb-comment-container'] {
        post_es,
        h.div['lb-comment-card lb-comment-add-post-card'] {
          style = 'animation-delay:' .. #post_es * 0.1 .. 's',
          h.button['lb-comment-add-post'] {
            risu_btn = "lb-interaction__lightboard-comments__AddPost",
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
      risu_btn = 'lb-reroll__lightboard-comments',
      type = 'button',
      h.lb_reroll_icon {
        closed = true
      },
    },
  }

  return tostring(html)
end

local function main(data)
  if not data or data == "" then
    return ""
  end

  local output = ""
  local lastIndex = 1

  local extractionSuccess, extractionResult = pcall(prelude.extractNodes, 'lightboard-comments', data)
  if not extractionSuccess then
    print("[LightBoard] Comments extraction failed:", tostring(extractionResult))
    return data
  end

  if extractionResult and #extractionResult > 0 then
    for i, match in ipairs(extractionResult) do
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      local processSuccess, processResult = pcall(render, match)
      if processSuccess then
        output = output .. processResult
      else
        print("[LightBoard] Comment parsing failed in block " .. i .. ":", tostring(processResult))
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
  function(tid, data, meta)
    setTriggerId(tid)

    if meta and meta.index ~= nil then
      local position = meta.index - getChatLength(triggerId)
      if position < -5 then
        return data
      end
    end

    local success, result = pcall(main, data)
    if success then
      return result
    else
      print("[LightBoard] Comment display failed:", tostring(result))
      return data
    end
  end
)
