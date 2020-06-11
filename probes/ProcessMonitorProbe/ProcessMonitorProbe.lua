setfenv(1, require "sysapi-ns")
local EventChannel = hp.EventChannel
local Process = require "process.Process"
local stringify = require "utils.stringify"
local ProcessEntity = hp.ProcessEntity

local CurrentProcessEntity = hp.CurrentProcessEntity

local PROCESS_ACCESS_STR = stringify.getTable("PROCESS_ACCESS")
local PAGE_PROTECT_STR = stringify.getTable("PAGE_PROTECT")

local band = bit.band
local bor = bit.bor
local toaddress = toaddress
local tonumber = tonumber
local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

---@param context EntryExecutionContext
local NtCreateUserProcess_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtCreateUserProcess_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local processEntity = ProcessEntity.fromHandle(context.p.ProcessHandle[0]):build()
    Event(
      "ProcessCreateEvent",
      {
        process = processEntity,
        actorProcess = CurrentProcessEntity
      }
    ):send(EventChannel.splunk)
  end
end

local PROCESS_SKIP_MASK =
  bor(PROCESS_QUERY_INFORMATION, PROCESS_QUERY_LIMITED_INFORMATION, PROCESS_SET_LIMITED_INFORMATION)

---@param context EntryExecutionContext
local NtOpenProcess_onEntry = function(context)
  local access = context.p.DesiredAccess
  if bor(access, PROCESS_SKIP_MASK) == PROCESS_SKIP_MASK then
    context:skipExitHook()
    return
  end

  if toaddress(context.p.ClientId.UniqueProcess) == ffi.C.GetCurrentProcessId() then
    context:skipExitHook()
    return
  end
end

---@param context ExitExecutionContext
local NtOpenProcess_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    Event(
      "ProcessAccessEvent",
      {
        actorProcess = CurrentProcessEntity,
        process = ProcessEntity.fromPid(toaddress(context.p.ClientId.UniqueProcess)):build(),
        access = stringify.mask(context.p.DesiredAccess, PROCESS_ACCESS_STR)
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local NtSetInformationProcess_onEntry = function(context)
  -- TODO: Here we need to determine potentially dangerous info classes
  -- skip to loud info classes
  local infoClass = context.p.ProcessInformationClass
  if
    infoClass == ffi.C.ProcessDefaultHardErrorMode or infoClass == ffi.C.ProcessResourceManagement or
      infoClass == ffi.C.ProcessLoaderDetour
   then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local NtSetInformationProcess_onExit = function(context)
  if NT_SUCCESS(context.p.retval) then
    Event(
      "ProcessModificationEvent",
      {
        actorProcess = CurrentProcessEntity,
        process = ProcessEntity.fromHandle(context.p.ProcessHandle):build(),
        infoType = tonumber(context.p.ProcessInformationClass)
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local NtSuspendProcess_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtSuspendProcess_onExit = function(context)
  if NT_SUCCESS(context.p.retval) then
    Event(
      "ProcessSuspendEvent",
      {
        actorProcess = CurrentProcessEntity,
        process = ProcessEntity.fromHandle(context.p.ProcessHandle):build()
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local NtDebugActiveProcess_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtDebugActiveProcess_onExit = function(context)
  if NT_SUCCESS(context.p.retval) then
    Event(
      "ProcessDebugEvent",
      {
        actorProcess = CurrentProcessEntity,
        process = ProcessEntity.fromHandle(context.p.ProcessHandle):build()
      }
    ):send(EventChannel.splunk)
  end
end

Probe {
  name = "ProcessMonitorProbe",
  hooks = {
    {
      name = "NtCreateUserProcessHook",
      onEntry = NtCreateUserProcess_onEntry,
      onExit = NtCreateUserProcess_onExit
    },
    {
      name = "NtOpenProcessHook",
      onEntry = NtOpenProcess_onEntry,
      onExit = NtOpenProcess_onExit
    },
    {
      name = "NtSetInformationProcessHook",
      onEntry = NtSetInformationProcess_onEntry,
      onExit = NtSetInformationProcess_onExit
    },
    {
      name = "NtSuspendProcessHook",
      onEntry = NtSuspendProcess_onEntry,
      onExit = NtSuspendProcess_onExit
    },
    {
      name = "NtDebugActiveProcessHook",
      onEntry = NtDebugActiveProcess_onEntry,
      onExit = NtDebugActiveProcess_onExit
    }
  }
}
