setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

Packages {
  "Interprocess Memory Write"
}

Case("mycase") {
  case = function()
    loadPackage("Interprocess Memory Write")

    local p = Process.run("notepad.exe")
    if p then
      local mem = p:memAlloc(4096)
      if mem then
        p:memWrite(mem, "test")
        p:memFree(mem)
      end

      p:terminate()
    end

    unloadPackage("Interprocess Memory Write")

    local events = fetchEvents("Interprocess Memory Write")
    assert(#events ~= 0)
  end
}
