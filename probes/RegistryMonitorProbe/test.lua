setfenv(1, require "sysapi-ns")

local File = require "file.File"
local Registry = require "registry.RegKey"

local package = Package "RegistryMonitorProbe"

Case("RegistryMonitorProbe") {
  case = function()
    local TEMP_KEY_PATH = "SOFTWARE"
    local TEMP_SUBKEY_NAME = "RegProbeTest"

    package:load()
    local key = Registry:create(HKEY_LOCAL_MACHINE, TEMP_KEY_PATH .. "\\" .. TEMP_SUBKEY_NAME)
    local val = ffi.new("DWORD[1]", 200)
    key:setVal("test1", REG_DWORD, val, ffi.sizeof("DWORD"))
    key:deleteValue("test1")

    key = nil
    local key = Registry:create(HKEY_LOCAL_MACHINE, TEMP_KEY_PATH)
    key:delete(TEMP_SUBKEY_NAME)

    local modificationEvents = fetchEvents("RegistryModificationEvent")
    assert(#modificationEvents ~= 0)

    local deleteValueEvents = fetchEvents("RegistryDeleteValueEvent")
    assert(#deleteValueEvents ~= 0)

    local deleteKeyEvents = fetchEvents("RegistryDeleteKeyEvent")
    assert(#deleteKeyEvents ~= 0)

    package:unload()
  end
}
