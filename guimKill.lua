local function healDismemberedUTF8(inputStr)
  local result_parts = {}
  local i = 1
  local n = #inputStr

  while i <= n do
    local first_tag_hex_content = string.match(inputStr, "^<0x(%x%x)>", i)

    if first_tag_hex_content then
      local bytes_in_sequence = {}
      local current_scan_pos = i
      local original_tags_start_pos = i

      while current_scan_pos <= n do
        local current_tag_hex = string.match(inputStr, "^<0x(%x%x)>", current_scan_pos)
        if current_tag_hex then
          table.insert(bytes_in_sequence, tonumber(current_tag_hex, 16))
          current_scan_pos = current_scan_pos + 6 -- Assuming fixed tag length like <0xAA>
        else
          break
        end
      end

      if #bytes_in_sequence > 0 then
        local temp_char_str = string.char(table.unpack(bytes_in_sequence))
        if utf8.len(temp_char_str) then
          table.insert(result_parts, temp_char_str)
        else
          table.insert(result_parts, string.sub(inputStr, original_tags_start_pos, current_scan_pos - 1))
        end
        i = current_scan_pos
      else
        table.insert(result_parts, string.sub(inputStr, i, i))
        i = i + 1
      end
    else
      table.insert(result_parts, string.sub(inputStr, i, i))
      i = i + 1
    end
  end
  return table.concat(result_parts)
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
