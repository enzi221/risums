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

local x = [[objective:
  title: 별의 인도와 에린의 번영
  content: 젠타리가 에린 부족의 수호자가 되어 원시 문명을 발전시키고 공존함
  completion: 0%
phase:
  title: 낯선 별의 손님과 숲의 아이들
  content: 젠타리와 에린 부족이 서로를 인식하고 신뢰의 첫 단추를 끼움
  stage: main
episodes[7|]{content|stage|state|title}:
  이방인과 원주민 간의 긴장 섞인 탐색전|introduction|done|그림자와 눈동자
  낯선 문물에 대한 호기심과 경계의 충돌|rise|ongoing|달콤한 이질감
  소통을 통한 상호 이해의 심화|rise|pending|언어의 다리
  예기치 못한 외부 자극에 대한 공동 대응|climax|pending|숲의 경고
  협력을 통한 위기 극복과 유대 형성|fall|pending|맞잡은 온기
  공동의 목표를 위한 거처 이동 결정|fall|pending|안식처를 향해
  새로운 관계 정립과 정착의 시작|conclusion|pending|수호자의 증명
divergence: low
comment: Ongoing E2 for 1 turn.
history: none]]

print(#toon.decode(x), tableToString(toon.decode(x)))
