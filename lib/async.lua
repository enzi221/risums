--- @meta Promise

--- @class Promise<T>: { await: fun(self: Promise<`T`>): `T` }
Promise = {}

--- @generic T
--- @param promises Promise<T>[]
--- @return Promise<T[]>
function Promise.all(promises) end

return Promise
