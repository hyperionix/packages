setfenv(1, require "sysapi-ns")

local Handle = require "handle.Handle"

local band = bit.band
local string = string
local EntityCache = hp.EntityCache
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel
local CurrentProcessEntity = hp.CurrentProcessEntity

local RegistryCache = EntityCache.new("RegistryCache", 64)
local WriteAccessMask = bit.bor(MAXIMUM_ALLOWED, KEY_SET_VALUE, DELETE)

local function getNameFromObjAttr(objAttr)
  local rootDir = objAttr.RootDirectory
  local result = ""

  if rootDir then
    local h = Handle.create(rootDir)
    local rootName = h.objectName
    if rootName then
      result = rootName
      if result:sub(-1) ~= "\\" then
        result = result .. "\\"
      end
    end
  end

  local objName = string.fromUS(objAttr.ObjectName)
  if objName then
    result = result .. objName
  end

  return result
end

---@param context EntryExecutionContext
local NtCreateKey_NtOpenKey_onEntry = function(context)
  if band(context.p.DesiredAccess, WriteAccessMask) == 0 then
    context:skipExitHook()
    return
  end
end

---@param context ExitExecutionContext
local NtCreateKey_NtOpenKey_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local flowData = {
      name = getNameFromObjAttr(context.p.ObjectAttributes)
    }

    RegistryCache:store(flowData, context.p.KeyHandle[0])
  end
end

---@param context EntryExecutionContext
local NtSetValueKey_onEntry = function(context)
  local flowData = RegistryCache:lookup(context.p.KeyHandle)
  if not flowData then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local NtSetValueKey_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local flowData = RegistryCache:lookup(context.p.KeyHandle)
    if flowData then
      Event(
        "RegistryModificationEvent",
        {
          actorProcess = CurrentProcessEntity,
          key = flowData.name,
          value = string.fromUS(context.p.ValueName),
          dataType = tonumber(context.p.Type),
          dataSize = tonumber(context.p.DataSize)
        }
      ):send(EventChannel.splunk)
    end
  end
end

---@param context EntryExecutionContext
local NtDeleteKey_NtDeleteValueKey_onEntry = function(context)
  local flowData = RegistryCache:lookup(context.p.KeyHandle)
  if not flowData then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local NtDeleteKey_NtDeleteValueKey_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local flowData = RegistryCache:lookup(context.p.KeyHandle)
    if flowData then
      local eventName
      local value
      if context.hook == "NtDeleteKeyHook" then
        eventName = "RegistryDeleteKeyEvent"
      else
        eventName = "RegistryDeleteValueEvent"
        value = string.fromUS(context.p.ValueName)
      end

      Event(
        eventName,
        {
          actorProcess = CurrentProcessEntity,
          key = flowData.name,
          value = value
        }
      ):send(EventChannel.file, EventChannel.splunk)
    end
  end
end

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  RegistryCache:delete(context.p.Handle)
end

Probe {
  name = "RegistryMonitorProbe",
  hooks = {
    {
      name = "NtCreateKeyHook",
      onEntry = NtCreateKey_NtOpenKey_onEntry,
      onExit = NtCreateKey_NtOpenKey_onExit
    },
    {
      name = "NtOpenKeyHook",
      onEntry = NtCreateKey_NtOpenKey_onEntry,
      onExit = NtCreateKey_NtOpenKey_onExit
    },
    {
      name = "NtOpenKeyExHook",
      onEntry = NtCreateKey_NtOpenKey_onEntry,
      onExit = NtCreateKey_NtOpenKey_onExit
    },
    {
      name = "NtSetValueKeyHook",
      onEntry = NtSetValueKey_onEntry,
      onExit = NtSetValueKey_onExit
    },
    {
      name = "NtDeleteKeyHook",
      onEntry = NtDeleteKey_NtDeleteValueKey_onEntry,
      onExit = NtDeleteKey_NtDeleteValueKey_onExit
    },
    {
      name = "NtDeleteValueKeyHook",
      onEntry = NtDeleteKey_NtDeleteValueKey_onEntry,
      onExit = NtDeleteKey_NtDeleteValueKey_onExit
    },
    {
      name = "NtClose",
      onEntry = NtClose_onEntry
    }
  }
}
