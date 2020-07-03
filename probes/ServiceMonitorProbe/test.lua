setfenv(1, require "sysapi-ns")
local ServiceManager = require "service.Manager"

local package = Package "ServiceMonitorProbe"

Case("DISABLED_ServiceMonitorProbe") {
  case = function()
    package:load()

    local mgr = ServiceManager.open()
    assert(mgr)

    mgr:forEachService(
      function(info)
      end,
      SERVICE_WIN32
    )

    local service = mgr:createService("TestService", "C:\\Windows\\System32\\TestSrv.exe")
    assert(service)

    service:delete()

    service = mgr:openService("Spooler")
    assert(service)

    service:control(SERVICE_CONTROL_STOP)

    service:start()

    local events = fetchEvents("ServiceCreateEvent")
    assert(#events ~= 0)
    events = fetchEvents("ServiceDeleteEvent")
    assert(#events ~= 0)
    events = fetchEvents("ServiceControlEvent")
    assert(#events ~= 0)
    events = fetchEvents("ServiceStartEvent")
    assert(#events ~= 0)
    events = fetchEvents("ServicesEnumerationEvent")
    assert(#events ~= 0)

    package:unload()
  end
}
