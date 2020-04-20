setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local File = require "file.File"

Packages {
  "File Opened For Write"
}

Case("mycase") {
  case = function()
    loadPackage("File Opened For Write")

    local fileName = fs.getTempDirectory() .. "\\testfile"
    local f = File.create(fileName, CREATE_ALWAYS, GENERIC_WRITE)
    f:close()

    unloadPackage("File Opened For Write")

    local events = fetchEvents("File Opened For Write")
    assert(#events ~= 0)
  end
}
