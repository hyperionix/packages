setfenv(1, require "sysapi-ns")
local bor = bit.bor
local File = require "file.File"

Packages {
  "Raw Disk Opened For Write"
}

Case("mycase") {
  case = function()
    loadPackage("Raw Disk Opened For Write")

    local f =
      File.create(
      [[\\.\C:]],
      OPEN_ALWAYS,
      bor(GENERIC_READ, GENERIC_WRITE),
      FILE_ATTRIBUTE_NORMAL,
      bor(FILE_SHARE_READ, FILE_SHARE_WRITE)
    )

    unloadPackage("Raw Disk Opened For Write")

    if f then
      local events = fetchEvents("Raw Disk Opened For Write")
      assert(#events ~= 0)
    end
  end
}
