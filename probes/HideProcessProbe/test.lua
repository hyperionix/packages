setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local package = Package "HideProcessProbe"

local TEST_PROCESS = "notepad.exe"

local function isProcessDetected(procName)
  procName = procName:lower()

  for name in Process.list() do
    if name:lower() == procName then
      return true
    end
  end

  return false
end

Case("mycase") {
  case = function()
    local p = Process.run(TEST_PROCESS)
    if p then
      assert(isProcessDetected(TEST_PROCESS) == true)
      package:load()
      assert(isProcessDetected(TEST_PROCESS) == false)
      package:unload()
      p:terminate()
    else
      LOG:err("Failed to create process " .. TEST_PROCESS)
    end
  end
}
