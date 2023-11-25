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

-- Pop byte from stack
function pop ()
	local s = memory.getregister("s") + 1
	memory.setregister("s", s)
	return memory.readbyte(0x100 + s, byte)
end

-- Jumps to the named address and waits for it to return. The PC is restored to
-- the same value after the subroutine. The currently-executing instruction
-- when calling this function should be a nop or compare. It can be an
-- instruction that writes to a register, as long as the value for the register
-- is not important. It must not be an instruction that writes to memory,
-- adjusts the stack, or changes the PC.
--
-- FCEUX's callbacks run in the middle of instruction processing and don't
-- provide single-clock stepping. The current instruction's execution must
-- complete before running the chosen subroutine, but it will run in a
-- corrupted manner.
function jsr (addr)
	assert(addr ~= nil, "addr must not be nil")
	local curaddr = memory.getregister("pc")

	-- Wait until FCEUX has finished the current instruction.
	-- NOP sled because FCEUX hasn't incremented the PC for the current
	-- instruction yet, and we don't know how long the instruction is.
	local lastnopaddr = 0x100 + memory.getregister("s")
	push(0xEA) -- NOP
	push(0xEA) -- NOP
	push(0xEA) -- NOP
	push(0xEA) -- NOP
	-- This may corrupt the current instruction, especially for multi-byte
	-- insturctions. The later bytes will be relative to this new pc.
	memory.setregister("pc", lastnopaddr-2)

	waitexecute(lastnopaddr)
	pop()
	pop()
	pop()
	pop()

	push(((curaddr-1)/256) % 256)
	push(((curaddr-1)    ) % 256)

	memory.setregister("pc", addr-1) -- -1 for the NOP's size
	waitexecute(curaddr)
end
