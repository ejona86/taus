require("ypcall") -- must be first, as it changes globals
require("asm")
require("testing")

local labels = asm.loadlabels("build/7bag.lbl")

local spawnTable = {0x02, 0x07, 0x08, 0x0A, 0x0B, 0x0E, 0x12}

function test_fullbag ()
	asm.waitexecute(0x813B) -- cmp gameModeState in @mainLoop
	asm.jsr(labels.disableNmi)
	local results = {}
	for _, orientID in pairs(spawnTable) do
		results[orientID] = 0
	end
	math.randomseed(1)
	memory.writebyte(labels.spawnID, 0)
	for i=1,14 do
		memory.writebyte(labels.rng_seed, math.random(256))
		asm.jsr(labels.pickRandomTetrimino_7bag)
		local a = memory.getregister("a")
		results[a] = results[a] + 1
	end
	print(results)
	for orientID, cnt in pairs(results) do
		assert(cnt == 2, "orientation: " .. orientID .. " count: " .. cnt)
	end
end

function test_distribution ()
	asm.waitexecute(0x813B) -- cmp gameModeState in @mainLoop
	asm.jsr(labels.disableNmi)
	local results = {}
	for _, orientID in pairs(spawnTable) do
		results[orientID] = 0
	end
	for i=0,255 do
		memory.writebyte(labels.spawnID, 0x7F)
		memory.writebyte(labels.rng_seed, i)
		asm.jsr(labels.pickRandomTetrimino_7bag)
		local a = memory.getregister("a")
		results[a] = results[a] + 1
	end
	print(results)
	for orientID, cnt in pairs(results) do
		assert(cnt == 36 or cnt == 37, "Imbalanced")
	end
end

testing.run()
