require("ypcall") -- must be first, as it changes globals
require("asm")
require("testing")

local labels = asm.loadlabels("build/taus.lbl")
local ntsc = labels["demoButtonsTable_indexIncr"] == 0x9DE8

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
	local startFrame = emu.framecount()
	memory.writebyte(labels.frameCounter+1, 5) -- force title screen timeout

	asm.waitexecute(0x8158) -- wait for demo to end
	if emu.framecount() - startFrame ~= (ntsc and 4760 or 3825) then
		error("frame count changed: " .. (emu.framecount()-startFrame))
	end
	assertbyteoff("score", 0, ntsc and 0x90 or 0x85)
	assertbyteoff("score", 1, ntsc and 0x42 or 0x21)
	assertbyteoff("score", 2, 0x00)
	assertbyteoff("DHT", 0, ntsc and 0x01 or 0x00)
	assertbyteoff("DHT", 1, 0x00)
	assertbyteoff("BRN", 0, ntsc and 0x02 or 0x04)
	assertbyteoff("BRN", 1, 0x00)
	assertbyteoff("EFF", 0, ntsc and 0x88 or 0x24)
	assertbyteoff("EFF", 1, 0x01)
	assertbyteoff("TRT", 0, ntsc and 0x57 or 0x30)
	assertbyteoff("TRT", 1, 0x00)
	assertbyteoff("TRNS", 0, ntsc and 0x86 or 0x43)
	assertbyteoff("TRNS", 1, ntsc and 0x40 or 0x19)
	assertbyteoff("TRNS", 2, 0x00)
	assertbyteoff("levelEffs", 0, math.floor((ntsc and 195 or 147)/2/3.125))
	assertbyteoff("levelEffs", 1, 0x00)
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
		local startcycles = debugger.getcyclescount()
		asm.jsr(labels.divmod)
		local cycles = debugger.getcyclescount() - startcycles
		print("cycles: " .. cycles)
		assertbyte("tmp1", math.floor(dividend / divisor))
		assertbyte("tmp2", dividend % divisor)
		asm.waitbefore()
		emu.poweron()
	end
end

function test_binaryToBcd ()
	local tests = {
		{0, 0x00},
		{10, 0x10},
		{999, 0x999},
		{454, 0x454},
		{134, 0x134},
	}
	for _, test in ipairs(tests) do
		asm.waitbefore()
		asm.waitbefore()
		local bin = test[1]
		local bcd = test[2]
		memory.writebyte(labels.tmp1, bin % 256)
		memory.setregister("a", bin / 256)
		local startcycles = debugger.getcyclescount()
		asm.jsr(labels.binaryToBcd)
		local cycles = debugger.getcyclescount() - startcycles
		print("cycles: " .. cycles)
		local a = memory.getregister("a")
		assert(a == (bcd % 256), "a: " .. a)
		assertbyte("tmp2", math.floor(bcd / 256))
		asm.waitbefore()
		emu.poweron()
	end
end

function test_multiplyBy100 ()
	local tests = {
		{0, 0},
		{3, 300},
		{100, 10000},
		{655, 65500},
	}
	for _, test in ipairs(tests) do
		asm.waitbefore()
		asm.waitbefore()
		local bin = test[1]
		local bcd = test[2]
		memory.writebyte(labels.tmp1, test[1] % 256)
		memory.writebyte(labels.tmp2, test[1] / 256)
		local startcycles = debugger.getcyclescount()
		asm.jsr(labels.multiplyBy100)
		local cycles = debugger.getcyclescount() - startcycles
		print("cycles: " .. cycles)
		assertbyte("tmp1", math.floor(test[2] % 256))
		assertbyte("tmp2", math.floor(test[2] / 256))
		asm.waitbefore()
		emu.poweron()
	end
end

function test_benchdoDiv ()
	asm.waitbefore()
	asm.waitbefore()
	local score = 7656 / 2
	local lines = 33 -- result = 232
	memory.writebyte(labels.tmp1, score % 256)
	memory.writebyte(labels.tmp2, score / 256)
	memory.setregister("a", lines)
	memory.setregister("pc", labels.doDiv)
	local startcycles = debugger.getcyclescount()
	asm.waitexecute(labels.statsPerLineClearDone)
	local cycles = debugger.getcyclescount() - startcycles
	print("cycles: " .. cycles)
	assertbyteoff("EFF", 0, 0x32)
	assertbyteoff("EFF", 1, 0x02)
end

-- If repeated, this can produce different results, because it doesn't sanitize
-- the current stats values.
function test_benchstatsPerLineClear ()
	asm.waitbefore()
	asm.waitbefore()
	memory.writebyte(labels.completedLines, 3)
	local startcycles = debugger.getcyclescount()
	asm.jsr(labels.statsPerLineClear)
	local cycles = debugger.getcyclescount() - startcycles
	print("cycles: " .. cycles)
end

testing.run()
