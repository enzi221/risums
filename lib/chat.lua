--- @meta

--- @class Chat
--- @field data string
--- @field role 'char'|'system'|'user'
local Chat = {}

--- @param triggerId string
--- @return string
function getCharacterLastMessage(triggerId) end

--- @param triggerId string
--- @return number
function getChatLength(triggerId) end

--- @param triggerId string
--- @return Chat[]
function getFullChat(triggerId) end

--- @param triggerId string
--- @param index number
--- @return Chat
function getChat(triggerId, index) end

--- @param triggerId string
--- @return number
function getChatLength(triggerId) end

--- @param triggerId string
--- @param index number
--- @param msg string
--- @return nil
function setChat(triggerId, index, msg) end

--- @param triggerId string
--- @param chats Chat[]
function setFullChat(triggerId, chats) end

--- @param triggerId string
--- @param index number
function removeChat(triggerId, index) end
