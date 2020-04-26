setfenv(1, require "sysapi-ns")
local bor = bit.bor
local File = require "file.File"

local package = Package "Raw Disk Write Access"

Case("mycase") {
  case = function()
    package:load()

    local f =
      File.create(
      [[\\.\C:]],
      OPEN_ALWAYS,
      bor(GENERIC_READ, GENERIC_WRITE),
      FILE_ATTRIBUTE_NORMAL,
      bor(FILE_SHARE_READ, FILE_SHARE_WRITE)
    )

    package:unload()

    if f then
      local events = fetchEvents("Raw Disk Write Access")
      assert(#events ~= 0)
    end
  end
}
