setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local bb = require "utils.bytebuf"

Packages {
  "Interprocess Thread Creation"
}

Case("mycase") {
  case = function()
    loadPackage("Interprocess Thread Creation")

    local p = Process.run("notepad.exe")
    if p then
      local buf = p:memAlloc(1024)
      if buf then
        local sc = bb.create([[\x90\x90\xC3]])
        p:memWrite(buf, sc)
        p:createThread(buf)
      end
      p:terminate()
    end

    unloadPackage("Interprocess Thread Creation")

    local events = fetchEvents("Interprocess Thread Creation")
    assert(#events ~= 0)
  end
}
