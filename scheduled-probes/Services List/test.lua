setfenv(1, require "sysapi-ns")
local ffi = require "ffi"
local C = ffi.C

ffi.cdef "unsigned int Sleep(unsigned int seconds);"

Packages {
  "Services List"
}

Case("mycase") {
  case = function()
    loadPackage("Services List")
    C.Sleep(2000)
    unloadPackage("Services List")
  end
}
