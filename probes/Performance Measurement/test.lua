setfenv(1, require "sysapi-ns")
local msvcrt = ffi.load("msvcrt")
local perf = require "utils.perf"
local vm = require "vm.vm"

local package = Package "NtQueryInformationProcess"

local ITER_COUNT = 1 * 1000 * 1000

local function nsToMs(ns)
  return ns / (1000 * 1000)
end

local function getPidBench()
  local t =
    perf.measure(
    function()
      ffi.C.GetProcessId(ffi.C.GetCurrentProcess())
    end,
    ITER_COUNT
  )
  return t
end

Case("perf1") {
  case = function()
    local pc1 = getPidBench()
    package:load()
    local pc2 = getPidBench()
    package:unload()

    print(ITER_COUNT .. " calls of GetProcessId()")
    print("(1) No probe")
    print("(2) Probe with emtpy hook")
    print("-------------------")

    local nsPerCall1 = pc1 / ITER_COUNT
    local nsPerCall2 = pc2 / ITER_COUNT
    local oh = nsPerCall2 - nsPerCall1
    local ohp = math.floor(oh / nsPerCall1 * 100)

    print("(1) Total: " .. nsToMs(pc1) .. " ms")
    print("(2) Total: " .. nsToMs(pc2) .. " ms")
    print("(1) Rate: " .. nsPerCall1 .. " ns/call")
    print("(2) Rate: " .. nsPerCall2 .. " ns/call")
    print("Overhead: " .. oh .. " ns/call, " .. ohp .. "%")
    -- print("Overhead: " .. (pc2 - pc1) .. " ns/call, " .. (pc1 / pc2) * 100 .. " %")
  end
}
