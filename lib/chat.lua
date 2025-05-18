--- @meta

--- @class Chat
--- @field data string
--- @field role 'char'|'system'|'user'
local Chat = {}

--- @param triggerId string
--- @return Chat[]
function getFullChat(triggerId) end

--- @param triggerId string
--- @param index number
--- @param msg string
--- @return nil
function setChat(triggerId, index, msg) end
