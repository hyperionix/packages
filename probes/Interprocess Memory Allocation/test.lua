setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local package = Package "Interprocess Memory Allocation"

Case("mycase") {
  case = function()
    package:load()

    local p = Process.run("notepad.exe")
    if p then
      local mem = p:memAlloc(4096)
      if mem then
        p:memFree(mem)
      end

      p:terminate()
    end

    package:unload()

    local events = fetchEvents("Interprocess Memory Allocation")
    assert(#events ~= 0)
  end
}
