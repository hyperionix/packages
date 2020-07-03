setfenv(1, require "sysapi-ns")
local Service = require "service.Service"
local ServiceManager = require "service.Manager"
local ServiceEntity = hp.ServiceEntity
local SharedTable = hp.SharedTable
local bor = bit.bor
local band = bit.band

local CurrentProcessEntity = hp.CurrentProcessEntity

local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

local isX64 = ffi.abi("64bit")
local RETVAL_REG = isX64 and "rax" or "eax"

local AllServicesCache = SharedTable.new("AllServicesCache", "number", 64)

-- access rights required for query status and config info about service
local QUERY_STATUS_CONFIG_ACCESS = bor(SERVICE_QUERY_STATUS, SERVICE_QUERY_CONFIG)

local mgr = ServiceManager.open(SC_MANAGER_CONNECT)

local function getServiceEntity(handle)
  local serviceEntry = AllServicesCache:get(handle)
  if serviceEntry then
    if band(serviceEntry.access, QUERY_STATUS_CONFIG_ACCESS) == QUERY_STATUS_CONFIG_ACCESS then
      -- required access rights are already granted, get entity from handle
      return ServiceEntity.fromHandle(handle):build()
    elseif mgr then
      local service = mgr:openService(serviceEntry.name, QUERY_STATUS_CONFIG_ACCESS)
      return ServiceEntity.fromSysapiService(service):build()
    end
  end
end

---@param context ExitExecutionContext
local CreateService_OpenService_onExit = function(context)
  local handle = ffi.cast("SC_HANDLE", context.r[RETVAL_REG])
  if handle ~= ffi.NULL then
    local serviceEntry = {
      name = (context.hook == "CreateServiceWHook" or context.hook == "OpenServiceWHook") and
        string.fromWC(context.p.lpServiceName) or
        ffi.string(context.p.lpServiceName),
      access = tonumber(context.p.dwDesiredAccess)
    }
    AllServicesCache:add(handle, serviceEntry)

    if context.hook == "CreateServiceWHook" or context.hook == "CreateServiceAHook" then
      Event(
        "ServiceCreateEvent",
        {
          actorProcess = CurrentProcessEntity,
          service = getServiceEntity(handle)
        }
      )
    end
  end
end

---@param context ExitExecutionContext
local CloseServiceHandle_onExit = function(context)
  if context.retval ~= 0 then
    AllServicesCache:delete(context.p.hSCObject)
  end
end

---@param context EntryExecutionContext
local DeleteService_onEntry = function(context)
  serviceEntity = getServiceEntity(context.p.hService)
end

---@param context ExitExecutionContext
local DeleteService_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "ServiceDeleteEvent",
      {
        actorProcess = CurrentProcessEntity,
        service = serviceEntity
      }
    )
  end
end

---@param context ExitExecutionContext
local ControlService_onExit = function(context)
  if context.retval ~= 0 then
    -- TODO: add to event status before operation
    Event(
      "ServiceControlEvent",
      {
        actorProcess = CurrentProcessEntity,
        service = getServiceEntity(context.p.hService),
        controlCode = tonumber(context.p.dwControl)
      }
    )
  end
end

---@param context ExitExecutionContext
local EnumServices_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "ServicesEnumerationEvent",
      {
        actorProcess = CurrentProcessEntity
      }
    )
  end
end

---@param context ExitExecutionContext
local StartService_onExit = function(context)
  if context.retval ~= 0 then
    local serviceEntity = getServiceEntity(context.p.hService)
    Event(
      "ServiceStartEvent",
      {
        actorProcess = CurrentProcessEntity,
        service = serviceEntity
      }
    )

    if
      serviceEntity and
        (serviceEntity.type == SERVICE_KERNEL_DRIVER or serviceEntity.type == SERVICE_FILE_SYSTEM_DRIVER)
     then
      Event(
        "DriverLoadEvent",
        {
          actorProcess = CurrentProcessEntity,
          service = serviceEntity
        }
      )
    end
  end
end

---@param context ExitExecutionContext
local NtLoadUnloadDriver_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    -- TODO: add more info about driver's service
    Event(
      context.hook == "NtLoadDriverHook" and "DriverLoadEvent" or "DriverUnloadEvent",
      {
        actorProcess = CurrentProcessEntity,
        driverServiceName = string.fromUS(context.p.DriverServiceName)
      }
    )
  end
end

Probe {
  name = "ServiceMonitorProbe",
  hooks = {
    {
      name = "CreateServiceAHook",
      onEntry = function(context)
      end,
      onExit = CreateService_OpenService_onExit
    },
    {
      name = "CreateServiceWHook",
      onEntry = function(context)
      end,
      onExit = CreateService_OpenService_onExit
    },
    {
      name = "OpenServiceAHook",
      onEntry = function(context)
      end,
      onExit = CreateService_OpenService_onExit
    },
    {
      name = "OpenServiceWHook",
      onEntry = function(context)
      end,
      onExit = CreateService_OpenService_onExit
    },
    {
      name = "CloseServiceHandleHook",
      onEntry = function(context)
      end,
      onExit = CloseServiceHandle_onExit
    },
    {
      name = "DeleteServiceHook",
      onEntry = DeleteService_onEntry,
      onExit = DeleteService_onExit
    },
    {
      name = "ControlServiceHook",
      onEntry = function(context)
      end,
      onExit = ControlService_onExit
    },
    {
      name = "ControlServiceExAHook",
      onEntry = function(context)
      end,
      onExit = ControlService_onExit
    },
    {
      name = "ControlServiceExWHook",
      onEntry = function(context)
      end,
      onExit = ControlService_onExit
    },
    {
      name = "EnumServicesStatusExAHook",
      onEntry = function(context)
      end,
      onExit = EnumServices_onExit
    },
    {
      name = "EnumServicesStatusExWHook",
      onEntry = function(context)
      end,
      onExit = EnumServices_onExit
    },
    {
      name = "EnumServicesStatusAHook",
      onEntry = function(context)
      end,
      onExit = EnumServices_onExit
    },
    {
      name = "EnumServiceGroupWHook",
      onEntry = function(context)
      end,
      onExit = EnumServices_onExit
    },
    {
      name = "StartServiceAHook",
      onEntry = function(context)
      end,
      onExit = StartService_onExit
    },
    {
      name = "StartServiceWHook",
      onEntry = function(context)
      end,
      onExit = StartService_onExit
    },
    {
      name = "NtLoadDriverHook",
      onEntry = function(context)
      end,
      onExit = NtLoadUnloadDriver_onExit
    },
    {
      name = "NtUnloadDriverHook",
      onEntry = function(context)
      end,
      onExit = NtLoadUnloadDriver_onExit
    }
  }
}
