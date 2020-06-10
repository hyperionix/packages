setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local share = require "share.share"

local package = Package "ShareMonitorProbe"

ffi.load("srvcli")

Case("DISABLED_ShareMonitorProbe") {
  case = function()
    package:load()

    local shareName = "TestShare"
    local sharePath = fs.getTempDirectory() .. "test"

    ffi.C.CreateDirectoryA(sharePath, ffi.NULL)

    local ret = share.add(shareName, sharePath)
    assert(ret == 0)

    local shareType = ffi.new("DWORD[1]")
    ret = share.check(sharePath, shareType)
    assert(ret == 0)
    assert(shareType[0] == STYPE_DISKTREE)

    share.forEach(
      function(info)
        print(string.fromWC(info.shi2_netname), string.fromWC(info.shi2_path))
      end,
      2
    )

    ret = share.delete(shareName)
    assert(ret == 0)

    ffi.C.RemoveDirectoryA(sharePath)

    local events = fetchEvents("ShareAddEvent")
    assert(#events ~= 0)
    events = fetchEvents("ShareCheckEvent")
    assert(#events ~= 0)
    events = fetchEvents("SharesEnumerationEvent")
    assert(#events ~= 0)
    events = fetchEvents("ShareDeleteEvent")
    assert(#events ~= 0)

    package:unload()
  end
}
