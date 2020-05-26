setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local File = require "file.File"

local package = Package "File Write"

Case("mycase") {
  case = function()
    package:load()
    local fileName = fs.getTempDirectory() .. "\\testfile"
    local f = File.create(fileName, CREATE_ALWAYS, GENERIC_WRITE)
    f:write("aaaaaaa")
    f:close()
    package:unload()

    local events = fetchEvents("File Write")
    assert(#events ~= 0)
  end
}
