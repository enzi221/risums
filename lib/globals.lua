--- @meta

--- @param type 'editDisplay'|'editOutput'|'editInput'
--- @param callback fun(triggerId: string, data: string, meta: { index: number }): string
--- @return nil
function listenEdit(type, callback) end

--- @param func fun(...): any
--- @return fun(...): any
function async(func) end

--- @param triggerId string
--- @param type 'char'|'user'
--- @param msg string
function addChat(triggerId, type, msg) end

--- @param triggerId string
--- @param msg string
function alertError(triggerId, msg) end

--- @param triggerId string
--- @param msg string
function alertNormal(triggerId, msg) end

--- @param triggerId string
--- @return string
function getAuthorsNote(triggerId) end

--- @param triggerId string
--- @param varName string
--- @return string?
function getGlobalVar(triggerId, varName) end

--- @generic T
--- @param triggerId string
--- @param varName string
--- @return T
function getState(triggerId, varName) end

--- @param triggerId string
--- @param varName string
--- @return string
function getChatVar(triggerId, varName) end

--- @param triggerId string
--- @param varName string
--- @param value string
function setChatVar(triggerId, varName, value) end

--- @param triggerId string
--- @param varName string
--- @param value any
--- @return nil
function setState(triggerId, varName, value) end

--- @param triggerId string
function stopChat(triggerId) end

null = {}
