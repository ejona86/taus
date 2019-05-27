-- Hack pcall so that it works with coroutines. It fixes the error "attempt to
-- yield across metamethod/C-call boundary". This is necessary for standard Lua
-- 5.1

require("coroutine")

print(_VERSION)

local comap = {}

-- pcall implemented using coroutines, to be compatible with coroutines
function pcall (func, ...)
	local co = coroutine.create(func)
	while true do
		comap[co] = coroutine.running()
		local res
		if arg then
			res = {coroutine.resume(co, unpack(arg))}
		else
			res = {coroutine.resume(co)}
		end
		comap[co] = nil
		arg = nil
		if not res[1] or coroutine.status(co) == "dead" then
			return unpack(res)
		else
			table.remove(res, 1)
			-- Luckily Lua 5.1 doesn't have coroutine.isyieldable().
			-- So this should only be triggered if we are already
			-- within a coroutine (and if we aren't, then the yield
			-- within 'func' is invalid).
			arg = coroutine.yield(unpack(res))
		end
	end
end

local savedcoroutinerunning = coroutine.running
-- Hide the coroutine we created. Since we prevent the coroutine we created from
-- being returned here and it doesn't escape from pcall(), we are guaranteed
-- that it won't be resume()d by someone else.
function coroutine.running ()
	local co = savedcoroutinerunning()
	local co2 = comap[co]
	if co2 then
		return co2
	end
	return co
end
