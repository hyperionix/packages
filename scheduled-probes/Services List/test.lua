setfenv(1, require "sysapi-ns")

local package = Package "Services List"

Case("mycase") {
  case = function()
    package:load()
    ffi.C.Sleep(2000)
    package:unload()
  end
}
