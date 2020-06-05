setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local package = Package "ProcessMonitorProbe"

Case("ProcessMonitorProbe") {
  case = function()
    package:load()
    local p = Process.run("notepad.exe")
    if p then
      local mem = p:memAlloc(1024, PAGE_READWRITE)
      p:memProtect(mem, 1024, PAGE_EXECUTE_READWRITE)
      p:terminate()
    end
    package:unload()
  end
}
