setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local File = require "file.File"

local package = Package "File Moved"

hp.cdef [[
  BOOL MoveFileA(
    LPCSTR lpExistingFileName,
    LPCSTR lpNewFileName
  );
]]

Case("mycase") {
  case = function()
    local tempDir = fs.getTempDirectory()
    local fileSrc = tempDir .. "\\test1.txt"
    local fileDst = tempDir .. "\\test2.txt"

    local f = File.create(fileSrc, CREATE_ALWAYS)
    f:close()

    package:load()
    ffi.C.MoveFileA(fileSrc, fileDst)
    package:unload()

    File.delete(fileDst)

    local events = fetchEvents("File Moved")
    assert(#events ~= 0)
  end
}
