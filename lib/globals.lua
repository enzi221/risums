--- @meta

--- @param type 'editDisplay'|'editOutput'|'editInput'
--- @param callback fun(triggerId: string, data: string): string
--- @return nil
function listenEdit(type, callback) end

--- @param func fun(...): any
--- @return fun(...): any
function async(func) end

--- @param triggerId string
--- @param msg string
function alertError(triggerId, msg) end

--- @param triggerId string
--- @param varName string
--- @return string?
function getGlobalVar(triggerId, varName) end
