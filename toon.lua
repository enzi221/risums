_ENV.prelude = {}

local toon = require('toon.decode')

local function tableToString(t, indent)
  indent = indent or 0
  if type(t) ~= "table" then
    return tostring(t)
  end
  local str = "{"
  local first = true
  for k, v in pairs(t) do
    if not first then str = str .. ", " end
    first = false
    str = str .. "[" .. tostring(k) .. "]="
    if type(v) == "table" then
      str = str .. tableToString(v, indent + 1)
    else
      str = str .. tostring(v)
    end
  end
  return str .. "}"
end

local x = [[scenes:
  - camera: from above, upper body, pov
    characters[1]:
      girl, adolescent, long platinum blonde hair, loose braid, blue eyes, slender
    locator: \"이어졌다.\"
    scene: "nsfw, 1girl, interior, bedroom, night, ::dark::3, bed"
  - camera: from behind, lower body
    characters[1]:
      girl, adolescent, platinum blonde hair, blue eyes, slender
    locator: \"찢었다.\"
    scene: "nsfw, 1girl, interior, bedroom, night, ::dark::3, bed"
  - camera: portrait, straight-on
    characters[1]:
      girl, adolescent, platinum blonde hair, blue eyes, slender
    locator: \"비집고 나왔다.\"
    scene: "nsfw, 1girl, interior, bedroom, night, ::dark::3"
keyvis:
  camera: cowboy shot, from side
  characters[1]:
    girl, adolescent, long platinum blonde hair, loose braid, blue eyes, slender
  scene: nsfw, 1girl, interior, bedroom, night, ::dark::3, cinematic lighting]]

print(#toon.decode(x), tableToString(toon.decode(x)))
