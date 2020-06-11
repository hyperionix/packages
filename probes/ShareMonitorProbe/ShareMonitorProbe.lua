setfenv(1, require "sysapi-ns")
local EventChannel = hp.EventChannel
local band = bit.band
local string = string

local CurrentProcessEntity = hp.CurrentProcessEntity

local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

local SHARE_TYPES_NAMES = {
  [STYPE_DISKTREE] = "Disk drive",
  [STYPE_PRINTQ] = "Print queue",
  [STYPE_DEVICE] = "Communication device",
  [STYPE_IPC] = "Interprocess communication (IPC)"
}

---@param context EntryExecutionContext
local NetShareEnum_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetShareEnum_onExit = function(context)
  if context.retval == 0 then
    Event(
      "SharesEnumerationEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer"
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local NetShareAdd_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetShareAdd_onExit = function(context)
  if context.retval == 0 then
    local info = ffi.cast("PSHARE_INFO_2", context.p.buf)

    Event(
      "ShareAddEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer",
        shareName = string.fromWC(info.shi2_netname),
        sharePath = string.fromWC(info.shi2_path),
        shareType = SHARE_TYPES_NAMES[band(info.shi2_type, STYPE_MASK)],
        temp = band(info.shi2_type, STYPE_TEMPORARY) ~= 0,
        special = band(info.shi2_type, STYPE_SPECIAL) ~= 0
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local NetShareDel_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetShareDel_onExit = function(context)
  if context.retval == 0 then
    local shareName
    if context.hook == "NetShareDelHook" then
      shareName = string.fromWC(context.p.netname)
    else
      local info = ffi.cast("PSHARE_INFO_0", context.p.buf)
      shareName = string.fromWC(info.shi0_netname)
    end

    Event(
      "ShareDeleteEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer",
        shareName = shareName
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local NetShareCheck_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetShareCheck_onExit = function(context)
  if context.retval == 0 then
    Event(
      "ShareCheckEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer",
        sharePath = string.fromWC(context.p.device)
      }
    ):send(EventChannel.splunk)
  end
end

Probe {
  name = "ShareMonitorProbe",
  hooks = {
    {
      name = "NetShareEnumHook",
      onEntry = NetShareEnum_onEntry,
      onExit = NetShareEnum_onExit
    },
    {
      name = "NetShareAddHook",
      onEntry = NetShareAdd_onEntry,
      onExit = NetShareAdd_onExit
    },
    {
      name = "NetShareDelHook",
      onEntry = NetShareDel_onEntry,
      onExit = NetShareDel_onExit
    },
    {
      name = "NetShareDelExHook",
      onEntry = NetShareDel_onEntry,
      onExit = NetShareDel_onExit
    },
    {
      name = "NetShareCheckHook",
      onEntry = NetShareCheck_onEntry,
      onExit = NetShareCheck_onExit
    }
  }
}
