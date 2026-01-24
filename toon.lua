_ENV.prelude = {}

local toon = require('toon.decode')

local function tableToString(t, indent)
  indent = indent or 0
  if type(t) ~= "table" then
    return tostring(t)
  end
  local pad = string.rep("  ", indent)
  local padInner = string.rep("  ", indent + 1)
  local str = "{\n"
  local first = true
  for k, v in pairs(t) do
    if not first then str = str .. ",\n" end
    first = false
    str = str .. padInner .. "[" .. tostring(k) .. "] = "
    if type(v) == "table" then
      str = str .. tableToString(v, indent + 1)
    else
      str = str .. tostring(v)
    end
  end
  return str .. "\n" .. pad .. "}"
end

local x = [[scenes[2]:
  - camera: cowboy shot
    characters[2]:
      girl, adolescent, black eyes, choppy bangs, medium straight black hair, slender, small breasts, white shirt, red neck ribbon, messy clothes, gray pencil skirt, lifted skirt, blush, sweat, trembling, hands on stomach, target#holding waist, looking away, panting
      boy, male, black hair, undercut, glasses, white shirt, standing, source#holding waist, mutual#kissing
    locator: 동맥이 뛰는 박동.
    scene: nsfw, 1girl, 1boy, interior, public restroom, tile wall, fluorescent light, afternoon
  - camera: upper body, from side
    characters[2]:
      girl, adolescent, black eyes, choppy bangs, medium straight black hair, messy hair, wet lips, blush, mutual#kissing, closed eyes, leaning on shoulder
      boy, male, black hair, undercut, glasses, white shirt, mutual#kissing, leaning against wall
    locator: 타일을 통해 번져 나간다.
    scene: nsfw, 1girl, 1boy, interior, public restroom, close-up, steam
keyvis:
  camera: cowboy shot, from side
  characters[2]:
    girl, adolescent, black eyes, choppy bangs, medium straight black hair, white shirt, red neck ribbon, gray pencil skirt, lifted skirt, bottomless, thighs, blush, sweat, closed eyes, leaning against wall, mutual#kissing
    boy, male, black hair, undercut, glasses, white shirt, pants down, mutual#kissing, source#holding waist
  scene: nsfw, 1girl, 1boy, interior, public restroom, tile wall, handrail, fluorescent light, evening, ::dark::2]]

print(tableToString(toon.decode(x)))
