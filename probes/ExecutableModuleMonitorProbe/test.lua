setfenv(1, require "sysapi-ns")

local package = Package "ExecutableModuleMonitorProbe"

Case("mycase") {
  case = function()
    package:load()
    local hmod = ffi.C.LoadLibraryA("iphlpapi.dll")
    assert(hmod ~= ffi.NULL)
    ffi.C.FreeLibrary(hmod)
    package:unload()

    local eventsLoaded = fetchEvents("ModuleLoadEvent")
    assert(#eventsLoaded ~= 0)

    local eventsUnloaded = fetchEvents("ModuleUnloadEvent")
    assert(#eventsUnloaded ~= 0)
  end
}
