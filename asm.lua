-- Lua helpers to interact with assembly.

local P = {}
asm = P

local assert = assert
local coroutine = coroutine
local emu = emu
local error = error
local io = io
local memory = memory
local string = string
local tonumber = tonumber
local unpack = unpack

local print = print

setfenv(1, P)

-- Returns a table mapping labels to addresses.
function loadlabels (filename)
	local labels = {}
	for line in io.lines(filename) do
		local addr, name = string.match(line, "^al ([0-9A-F]+) %.(.*)$")
		if addr ~= nil then
			labels[name] = tonumber(addr, 16)
		end
	end
	return labels
end

local function resume (co, ...)
	local ok, err = coroutine.resume(co, unpack(arg))
	if not ok then
		error(err)
	end
end

-- Waits until addr is written. memory.registerwrite does not actually provide
-- the write in 'value', so it is not returned here.
function waitwrite (addr)
	assert(addr ~= nil, "addr must not be nil")
	local co = coroutine.running()
	memory.registerwrite(addr, function ()
		memory.registerwrite(addr, nil)
		resume(co)
	end)
	coroutine.yield()
end

-- Waits until addr is executed
function waitexecute (addr)
	assert(addr ~= nil, "addr must not be nil")
	local co = coroutine.running()
	memory.registerexecute(addr, function ()
		memory.registerexecute(addr, nil)
		resume(co)
	end)
	coroutine.yield()
end

-- Waits until before the frame is emulated
function waitbefore ()
	local co = coroutine.running()
	emu.registerbefore(function ()
		emu.registerbefore(nil)
		resume(co)
	end)
	coroutine.yield()
end

-- Waits until after the frame is emulated
function waitafter ()
	local co = coroutine.running()
	emu.registerafter(function ()
		emu.registerafter(nil)
		resume(co)
	end)
	coroutine.yield()
end

-- Push byte onto stack
function push (byte)
	local s = memory.getregister("s")
	memory.writebyte(0x100 + s, byte)
	memory.setregister("s", s-1)
end

local jsrretaddr = 1 -- arbitrary address that is not executed elsewhere
-- Jumps to the named address and waits for it to return
function jsr (addr)
	assert(addr ~= nil, "addr must not be nil")
	local curaddr = memory.getregister("pc")
	push(((jsrretaddr-1)/256) % 256)
	push(((jsrretaddr-1)    ) % 256)
	memory.setregister("pc", addr)

	waitexecute(jsrretaddr)
	memory.setregister("pc", curaddr)
end
