setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local File = require "file.File"

local package = Package "FileCopyProbe"

Case("mycase") {
  case = function()
    local fileSrc = fs.getTempDirectory() .. "\\srcTest"
    local fileDst = fs.getTempDirectory() .. "\\dstTest"

    local f = File.create(fileSrc, CREATE_ALWAYS)
    f:write("222")
    f:close()

    package:load()
    ffi.C.CopyFileA(fileSrc, fileDst, false)
    package:unload()

    local events = fetchEvents("FileCopyEvent")
    assert(#events ~= 0)
  end
}
