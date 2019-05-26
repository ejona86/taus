require("ypcall") -- must be first, as it changes globals
require("asm")
require("testing")

local labels = asm.loadlabels("build/taus.lbl")

function assertbyte (label, expected)
	local b = memory.readbyte(labels[label])
	if b ~= expected then
		error(label .. " expected: " .. expected .. " actual: " .. b)
	end
end

function assertbyteoff (label, off, expected)
	local b = memory.readbyte(labels[label] + off)
	if b ~= expected then
		error(label .. "+" .. off .. " expected: " .. expected .. " actual: " .. b)
	end
end

function test_demo ()
	asm.waitexecute(0x823F)
	joypad.set(1, {start=true}) -- skip legal
	asm.waitbefore()
	joypad.set(1, {start=nil})
	asm.waitexecute(0x828D)
	memory.writebyte(labels.frameCounter+1, 5) -- force title screen timeout

	asm.waitexecute(0x8158) -- wait for demo to end
	assertbyteoff("score", 0, 0x90)
	assertbyteoff("score", 1, 0x42)
	assertbyteoff("score", 2, 0x00)
	assertbyteoff("DHT", 0, 0x01)
	assertbyteoff("DHT", 1, 0x00)
	assertbyteoff("BRN", 0, 0x02)
	assertbyteoff("BRN", 1, 0x00)
	assertbyteoff("EFF", 0, 0x88)
	assertbyteoff("EFF", 1, 0x01)
end

function test_divmod ()
	local tests = {
		{1234, 43},
		{0, 1},
		{234, 234},
		{255*255, 255},
	}
	for _, test in ipairs(tests) do
		asm.waitbefore()
		asm.waitbefore()
		local dividend = test[1]
		local divisor = test[2]
		memory.writebyte(labels.tmp1, dividend % 256)
		memory.writebyte(labels.tmp2, dividend / 256)
		memory.setregister("a", divisor)
		asm.jsr(labels.divmod)
		assertbyte("tmp1", math.floor(dividend / divisor))
		assertbyte("tmp2", dividend % divisor)
		asm.waitbefore()
		emu.poweron()
	end
end

testing.run()
