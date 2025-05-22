--- @meta

--- @class Prompt
--- @field content string
--- @field role 'char'|'system'|'user'
local Prompt = {}

--- @class LLMResult
--- @field result string
--- @field success boolean
local LLMResult = {}

--- @param triggerId string
--- @param prompt Prompt[]
--- @return LLMResult
function LLM(triggerId, prompt) end

--- @param triggerId string
--- @param prompt Prompt[]
--- @return LLMResult
function axLLM(triggerId, prompt) end

--- @param triggerId string
--- @param text string
--- @return Promise<number>
function getTokens(triggerId, text) end
