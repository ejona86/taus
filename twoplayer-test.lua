require("ypcall") -- must be first, as it changes globals
require("asm")
require("testing")

local labels = asm.loadlabels("build/twoplayer.lbl")
local ntsc = labels["demoButtonsTable_indexIncr"] == 0x9DE8

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
	memory.writebyte(labels.numberOfPlayers, 2)
	memory.writebyte(labels.frameCounter+1, 5) -- force title screen timeout

	-- wait for gameModeState_initGameState to end
	asm.waitexecute(labels.makePlayer1Active-1)
	memory.registerexecute(labels.nmi, function ()
		debugger.resetcyclescount()
	end)
	memory.registerexecute(labels.copyOamStagingToOam_mod+10, function ()
		if debugger.getcyclescount() > 2270 then
			error("too long in nmi: " .. debugger.getcyclescount())
		end
	end)

	asm.waitexecute(0x8158) -- wait for demo to end
	if emu.framecount() - startFrame ~= (ntsc and 4760 or 3825) then
		error("frame count changed: " .. (emu.framecount()-startFrame))
	end
	assertbyteoff("player1_score", 0, ntsc and 0x90 or 0x85)
	assertbyteoff("player1_score", 1, ntsc and 0x42 or 0x21)
	assertbyteoff("player1_score", 2, 0x00)
	assertbyteoff("player2_score", 0, ntsc and 0x90 or 0x85)
	assertbyteoff("player2_score", 1, ntsc and 0x42 or 0x21)
	assertbyteoff("player2_score", 2, 0x00)
end

testing.run()
