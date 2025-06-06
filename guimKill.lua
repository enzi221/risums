local function healDismemberedUTF8(str)
  local out, buf = {}, {}
  local function flush()
    if #buf > 0 then
      local s = string.char(table.unpack(buf))
      if utf8.len(s) then
        out[#out+1] = s
      else
        for _,b in ipairs(buf) do
          out[#out+1] = string.format("<0x%02x>", b)
        end
      end
      buf = {}
    end
  end
  local i = 1
  while true do
    local s,e,hex = str:find("<0x(%x%x)>", i)
    if not s then break end
    if s > i then
      flush()
      out[#out+1] = str:sub(i, s-1)
    end
    buf[#buf+1] = tonumber(hex,16)
    i = e + 1
  end
  flush()
  if i <= #str then out[#out+1] = str:sub(i) end
  return table.concat(out)
end

local function main(tid)
  local chat = getChat(tid, -1)
  if chat then
    setChat(tid, -1, healDismemberedUTF8(chat.data))
  end
end

onOutput = async(function(tid)
  local success, result = pcall(main, tid)

  if not success then
    print("[GuimKill] Error: " .. tostring(result))
  end
end)
