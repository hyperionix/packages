setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local bb = require "utils.bytebuf"

local package = Package "InterprocessThreadCreateProbe"

Case("mycase") {
  case = function()
    package:load()

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

    package:unload()

    local events = fetchEvents("InterprocessThreadCreateEvent")
    assert(#events ~= 0)
  end
}
