setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

Packages {
  "Process Created"
}

Case("mycase") {
  case = function()
    loadPackage("Process Created")

    local p = Process.run("notepad.exe")
    if p then
      p:terminate()
      local events = fetchEvents("Process Created")
      assert(#events ~= 0)
    end

    unloadPackage("Process Created")
  end
}
