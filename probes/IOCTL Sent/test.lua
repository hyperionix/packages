setfenv(1, require "sysapi-ns")
local File = require "file.File"

local package = Package "IOCTL Sent"

ffi.cdef [[
  typedef struct _BEEP_SET_PARAMETERS {
    ULONG Frequency;
    ULONG Duration;
  } BEEP_SET_PARAMETERS, *PBEEP_SET_PARAMETERS;
]]

Case("mycase") {
  case = function()
    package:load()
    local f = File.create([[\\.\GLOBALROOT\Device\Beep]], OPEN_EXISTING, GENERIC_READ)
    if f then
      local code = CTL_CODE(FILE_DEVICE_BEEP, 0, METHOD_BUFFERED, FILE_ANY_ACCESS)
      local params = ffi.new("BEEP_SET_PARAMETERS")
      params.Frequency = 100
      params.Duration = 1
      if f:ioctl(code, params) ~= 0 then
        local events = fetchEvents("IOCTL Sent")
        assert(#events ~= 0)
      end
    end
    package:unload()
  end
}
