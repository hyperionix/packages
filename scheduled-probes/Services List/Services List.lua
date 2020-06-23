setfenv(1, require "sysapi-ns")
local ServiceManager = require "service.Manager"
local EventChannel = hp.EventChannel
local bor = bit.bor
local tinsert = table.insert
local string = string

ScheduledProbe {
  name = "Services List",
  intervalMS = 1 * 60 * 1000,
  callback = function()
    local mgr = ServiceManager.open(bor(SC_MANAGER_CONNECT, SC_MANAGER_ENUMERATE_SERVICE))
    if mgr then
      local services = {}
      mgr:forEachService(
        function(info)
          services[#services + 1] = {
            name = string.toUTF8(info.lpServiceName),
            display_name = string.toUTF8(info.lpDisplayName),
            state = info.ServiceStatusProcess.dwCurrentState,
            type = info.ServiceStatusProcess.dwServiceType,
            pid = info.ServiceStatusProcess.dwProcessId,
            flags = info.ServiceStatusProcess.dwServiceFlags
          }
        end,
        SERVICE_WIN32
      )

      mgr:close()

      Event("Services List", {services = services})
    end
  end
}
