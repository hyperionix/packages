setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

Packages {
  "Interprocess Memory Allocation"
}

Case("mycase") {
  case = function()
    loadPackage("Interprocess Memory Allocation")

    local p = Process.run("notepad.exe")
    if p then
      local mem = p:memAlloc(4096)
      if mem then
        p:memFree(mem)
      end

      p:terminate()
    end

    unloadPackage("Interprocess Memory Allocation")

    local events = fetchEvents("Interprocess Memory Allocation")
    assert(#events ~= 0)
  end
}
