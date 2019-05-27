-- Test framework. Create global functions starting with "test_" and then call
-- testing.run(). The test is run in a coroutine to allow yielding.

require("coroutine")
require("asm")

local P = {}
testing = P

local _G = _G
local asm = asm
local coroutine = coroutine
local emu = emu
local error = error
local os = os
local pairs = pairs
local pcall = pcall
local print = print
local string = string

setfenv(1, P)

local function run_ ()
	emu.registerexit(function () os.exit(1) end)
	emu.speedmode("maximum")
	local pass = 0
	local fail = 0
	for testname, testfunc in pairs(_G) do
		if string.match(testname, "^test_") then
			print("Running " .. testname)

			local ok, err = pcall(testfunc)
			if ok then
				pass = pass + 1
			else
				fail = fail + 1
				print(testname .. " failed:\n" .. err)
			end
			asm.waitbefore()
			emu.poweron()
		end
	end
	print("Passed: " .. pass .. " Failed: " .. fail)
	if fail == 0 then
		os.exit(0)
	else
		os.exit(1)
	end
end

-- Run test_* functions within a coroutine. May return before all tests are
-- complete. Exits process with exit code 0 on success and 1 on failure.
function run ()
	local co = coroutine.create(run_)
	local ok, err = coroutine.resume(co)
	if not ok then
		error(err)
	end
end
