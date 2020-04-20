setfenv(1, require "sysapi-ns")
local ServiceManager = require "service.Manager"

local bor = bit.bor
local tinsert = table.insert

ScheduledProbe {
  name = "Services List",
  interval = 1 * 60 * 1000, -- ms
  callback = function()
    local mgr = ServiceManager.open(bor(SC_MANAGER_CONNECT, SC_MANAGER_ENUMERATE_SERVICE))
    if not mgr then
      return
    end

    local services = {}
    mgr:forEachService(
      function(info)
        tinsert(
          services,
          {
            name = string.toUTF8(info.lpServiceName),
            display_name = string.toUTF8(info.lpDisplayName),
            state = info.ServiceStatusProcess.dwCurrentState,
            type = info.ServiceStatusProcess.dwServiceType,
            pid = info.ServiceStatusProcess.dwProcessId,
            flags = info.ServiceStatusProcess.dwServiceFlags
          }
        )
      end,
      SERVICE_WIN32_OWN_PROCESS
    )

    return {
      events = {
        Event {
          name = "Services List",
          services = services
        }:saveTo("splunk", "file")
      }
    }
  end
}
