--- @meta

--- @class LoreBook
--- @field alwaysActive boolean
--- @field comment string
--- @field content string
--- @field insertorder number
--- @field key string
--- @field priority number
--- @field secondKey string
loreBook = {}

--- @param triggerId string
--- @param search string
--- @return LoreBook[]
function getLoreBooks(triggerId, search) end

--- @param triggerId string
--- @param reserve number
--- @return LoreBook[]
function loadLoreBooks(triggerId, reserve) end

--- @param triggerId string
--- @return string
function getPersonaDescription(triggerId) end

--- @param triggerId string
--- @return string
function getPersonaName(triggerId) end
