require("ypcall") -- must be first, as it changes globals
require("asm")
require("testing")

local labels = asm.loadlabels("build/7bag.lbl")

function test_fullbag ()
	asm.waitbefore()
	asm.waitbefore()
	local spawnTable = {0x02,0x07,0x08,0x0A,0x0B,0x0E,0x12}
	math.randomseed(1)
	memory.writebyte(labels.spawnID, 0)
	local results = {}
	for i=1,14 do
		asm.waitbefore()
		memory.writebyte(labels.rng_seed, math.random(256))
		asm.jsr(labels.pickRandomTetrimino_7bag)
		local a = memory.getregister("a")
		if results[a] == nil then
			results[a] = 0
		end
		results[a] = results[a] + 1
	end
	for _, orientID in ipairs(spawnTable) do
		local cnt = results[orientID]
		assert(cnt == 2, "orientation: " .. orientID .. " count: " .. cnt)
	end
end

function test_distribution ()
	local spawnTable = {0x02,0x07,0x08,0x0A,0x0B,0x0E,0x12}
	math.randomseed(1)
	local results = {}
	for i=1,100*7 do
		asm.waitbefore()
		asm.waitbefore()
		memory.writebyte(labels.spawnID, 0)
		memory.writebyte(labels.rng_seed, math.random(256))
		asm.jsr(labels.pickRandomTetrimino_7bag)
		local a = memory.getregister("a")
		if results[a] == nil then
			results[a] = 0
		end
		results[a] = results[a] + 1
		asm.waitbefore()
		emu.poweron()
	end
	local imbalanced = false
	for _, orientID in ipairs(spawnTable) do
		local cnt = results[orientID]
		print("orientation: " .. orientID .. " count: " .. cnt)
		if cnt < 80 or cnt > 120 then
			imbalanced = true
		end
	end
	assert(not imbalanced, "Imbalanced")
end

testing.run()
