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
	elseif labels.chartEffConvert == labels.div2 then
		chartEffConvertDivisor = 2
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

testing.run()
