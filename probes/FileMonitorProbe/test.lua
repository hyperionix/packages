setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local File = require "file.File"

local package = Package "FileMonitorProbe"

Case("FileMonitorProbe") {
  case = function()
    local tempDir = fs.getTempDirectory()
    local fileName1 = tempDir .. "\\test1.txt"
    local fileName2 = tempDir .. "\\test2.txt"
    local fileName3 = tempDir .. "\\test3.txt"

    package:load()

    local f = File.create(fileName1, CREATE_ALWAYS)
    f:write("aaaa")
    -- f:read()
    f:close()

    f = File.create(fileName1 .. ":stream1", CREATE_ALWAYS)
    f:close()

    ffi.C.CopyFileA(fileName1, fileName2, false)
    ffi.C.MoveFileA(fileName1, fileName3)
    File.delete(fileName2)
    File.delete(fileName3)

    File.delete(fileName1)

    package:unload()
    -- File.delete(fileName1)
    -- File.delete(fileName2)
    -- File.delete(fileName3)
  end
}
