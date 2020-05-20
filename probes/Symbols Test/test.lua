setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local File = require "file.File"

local package = Package "Symbols Test"

local ffi = require "ffi"
local ok, ret = pcall(ffi.cdef, [[
HMODULE LoadLibraryA(
  LPCSTR lpLibFileName
);
]])

Case("mycase") {
  case = function()
    package:load()
    local hmod = ffi.C.LoadLibraryA("dnsapi.dll")
    package:unload()

    local events = fetchEvents("Symbols Test")
    assert(#events ~= 0)
  end
}
