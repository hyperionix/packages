setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local package = Package "Process Created"

Case("mycase") {
  case = function()
    package:load()

    local p = Process.run("notepad.exe")
    if p then
      p:terminate()
      local events = fetchEvents("Process Created")
      assert(#events ~= 0)
    end

    package:unload()
  end
}
