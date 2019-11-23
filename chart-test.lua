require("ypcall") -- must be first, as it changes globals
require("asm")
require("testing")

local labels = asm.loadlabels("build/taus.lbl")

function test_chartEffConvert ()
	local chartEffConvertDivisor
	if labels.chartEffConvert == labels.div3 then
		chartEffConvertDivisor = 3
	elseif labels.chartEffConvert == labels.div3125 then
		chartEffConvertDivisor = 3.125
	else
		error("unknown chartEffConvert")
	end
	for i=0,255 do
		asm.waitbefore()
		asm.waitbefore()
		local raw = i / chartEffConvertDivisor
		local expected = math.floor(i / chartEffConvertDivisor)
		memory.setregister("a", i)
		asm.jsr(labels.chartEffConvert)
		local result = memory.getregister("a")
		if result ~= expected then
			error("i " .. i .. " expected: " .. expected .. " actual: " .. result .. " raw: " .. raw)
		end
		asm.waitbefore()
		emu.poweron()
	end
end

function test_drawChartBackground ()
	asm.waitbefore()
	asm.waitbefore()
	local levelEffs = {8, 8, 9, 9, 8, 9, 16, 17, 48, 1}
	for i, levelEffs in ipairs(levelEffs) do
		memory.writebyte(labels.levelEffs+(i-1), levelEffs)
	end

	asm.jsr(labels.drawChartBackground)
	local n = 0x48 -- none
	local r = 0x49 -- right
	local l = 0x4A -- left
	local b = 0x4B -- both
	local gn = 0x50 -- gridline none
	local gr = 0x51 -- gridline right
	local gl = 0x52 -- gridline left
	local gb = 0x53 -- gridline both
	local goldenPlayfield = {
		{gn, gn, gn, gn, gn, gn, gn, gn, gn, gn},
	        { n,  n,  n,  n,  l,  n,  n,  n,  n,  n},
		{gn, gn, gn, gn, gl, gn, gn, gn, gn, gn},
	        { n,  n,  n,  n,  l,  n,  n,  n,  n,  n},
		{gn, gn, gn, gr, gl, gn, gn, gn, gn, gn},
	        { n,  b,  r,  b,  l,  n,  n,  n,  n,  n},
	}
	local failed = false
	for i, row in ipairs(goldenPlayfield) do
		i = i - 1
		for j, expected in ipairs(row) do
			j = j - 1
			local b = memory.readbyte(labels.playfield + (14 + i) * 10 + j)
			if b ~= expected then
				failed = true
				print(string.format("playfield (%d,%d) expected: %X actual: %X", i, j, expected, b))
			end
		end
	end
	if failed then
		error("playfield did not match expected")
	end
end

function test_drawChartSprites ()
	asm.waitbefore()
	asm.waitbefore()
	local levelEffs = {
		48, 14, 14, 48,
		16, 14, 14, 16,
		16, 8, 8, 16,
		9, 8, 14, 0,
		0, 0, 0, 0,
	}
	for i, levelEffs in ipairs(levelEffs) do
		memory.writebyte(labels.levelEffs+(i-1), levelEffs)
	end

	memory.writebyte(labels.oamStagingLength, 0)
	asm.jsr(labels.drawChartBackground)
	asm.jsr(labels.drawChartSprites)
	local d0 = 0x40 -- endcap, diff 0
	local d1 = 0x41 -- endcap, diff 1
	local d2 = 0x42 -- endcap, diff 2
	local d3 = 0x43 -- endcap, diff 3
	local d4 = 0x44 -- endcap, diff 4
	local d5 = 0x45 -- endcap, diff 5
	local d6 = 0x46 -- endcap, diff 6
	local d7 = 0x47 -- endcap, diff 7
	local f = 0x4C -- seven-pixel filler
	local e = 0x4D -- single endcap
	local an = 0x22 -- attributes, normal
	local af = 0x62 -- attributes, flip horiz
	local goldenSprites = {
		-- Y, Tile, Attr, X
		{48  ,  e, an,  0},
		{14  ,  e, af,  0},
		{14  ,  e, an,  8},
		{48  ,  e, af,  8},
		{14+7, d2, af, 16},
		{14-1,  f, af, 16},
		{14+7, d2, an, 24},
		{14-1,  f, an, 24},
		{16  ,  e, an, 32},
		{ 8  ,  e, af, 32},
		{ 8  ,  e, an, 40},
		{16  ,  e, af, 40},
		{ 8+7, d1, af, 48},
		{ 8-1,  f, af, 48},
		{14  ,  e, an, 56},
	}
	for _, sprite in ipairs(goldenSprites) do
		sprite[1] = 0x2F + 20 * 8 - sprite[1]
		sprite[4] = 0x60 + sprite[4]
	end

	local failed = false
	local expected = #goldenSprites * 4
	local actual = memory.readbyte(labels.oamStagingLength)
	if actual ~= expected then
		failed = true
		print(string.format("oamStagingLength expected: %d actual %d", expected, actual))
	end
	for i, sprite in ipairs(goldenSprites) do
		i = i - 1
		for j, expected in ipairs(sprite) do
			j = j - 1
			local b = memory.readbyte(labels.oamStaging + (i * 4) + j)
			if b ~= expected then
				failed = true
				print(string.format("oamStaging (%d,%d) expected: %X actual: %X", i, j, expected, b))
			end
		end
	end
	if failed then
		error("oamStaging did not match expected")
	end
end

testing.run()
